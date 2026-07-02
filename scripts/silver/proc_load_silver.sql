/*
========================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
========================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to
    populate the 'silver' schema tables from the 'bronze' schema.
    Actions Performed:
    - Truncates Silver tables.
    - Inserts transformed and cleansed data from Bronze into Silver tables.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
========================================================================
*/
CREATE or alter PROCEDURE silver.silver_load as 
BEGIN
    DECLARE @start_time DATETIME , @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
    begin try 
            set @batch_start_time = GETDATE();
            print '==============================================';
            print 'Loading silver Layer';
            print '==============================================';


            print'-----------------------------------------------';
            print'Loading CRM Tables';
            print'-----------------------------------------------';

            -- loading silver.crm_cust_info
            set @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_cust_info' TRUNCATE TABLE silver.crm_cust_info PRINT '>> Inserting Data Into: silver.crm_cust_info'
        INSERT into
            silver.crm_cust_info (
                cst_id,
                cst_key,
                cst_firstname,
                cst_lastname,
                cst_marital_status,
                cst_gndr,
                cst_create_date
            )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname) as cst_firstname,
            TRIM(cst_lastname) as cst_lastname,
            case
                WHEN UPPER(TRIM(cst_marital_status)) = 's' THEN 'Sinngle'
                WHEN UPPER(TRIM(cst_marital_status)) = 'm' THEN 'Married'
                ELSE 'n/a'
            END as cst_marital_status,
            case
                WHEN UPPER(TRIM(cst_gndr)) = 'f' THEN 'Female'
                WHEN UPPER(TRIM(cst_gndr)) = 'm' THEN 'Male'
                ELSE 'n/a'
            END as cst_gndr,
            cst_create_date
        FROM
            (
                SELECT
                    *,
                    ROW_NUMBER() OVER (
                        PARTITION BY cst_id
                        ORDER BY
                            cst_create_date desc
                    ) as flag_last
                FROM
                    bronze.crm_cust_info
                WHERE
                    cst_id IS NOT NULL
            ) t
        WHERE
            flag_last = 1;
        set @end_time = GETDATE();
        print 'Load Duration: ' + cast(DATEDIFF(SECOND,@start_time,@end_time) as NVARCHAR) + ' seconds';
        print '>>--------------------';

        set @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_prd_info' TRUNCATE TABLE silver.crm_prd_info PRINT '>> Inserting Data Into: silver.crm_prd_info'
        INSERT into
            silver.crm_prd_info (
                prd_id,
                cat_id,
                prd_key,
                prd_nm,
                prd_cost,
                prd_line,
                prd_start_dt,
                prd_end_dt
            )
        SELECT
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') as cat_id,
            SUBSTRING(prd_key, 7, LEN(prd_key)) as prd_key,
            prd_nm,
            ISNULL(prd_cost, 0) AS prd_cost,
            CASE
                UPPER(TRIM(prd_line))
                WHEN 'M' then 'Mountain'
                WHEN 'R' then 'Road'
                WHEN 'S' then 'Other Sales'
                WHEN 'T' then 'Touring'
                ELSE 'n/a'
            END AS prd_line,
            CAST(prd_start_dt AS date) AS prd_start_dt,
            CAST(
                LEAD(prd_start_dt) OVER (
                    PARTITION BY prd_key
                    ORDER BY
                        prd_start_dt
                ) -1 as date
            ) AS prd_end_date
        from
            bronze.crm_prd_info;
        SET @end_time = GETDATE();
        print 'Load Duration: ' + cast(DATEDIFF(SECOND,@start_time,@end_time) as NVARCHAR) + ' seconds';
        print '>>--------------------';

        set @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_sales_details' TRUNCATE TABLE silver.crm_sales_details PRINT '>> Inserting Data Into: silver.crm_sales_details'
        INSERT into
            silver.crm_sales_details(
                sls_ord_num,
                sls_prd_key,
                sls_cust_id,
                sls_order_dt,
                sls_ship_dt,
                sls_due_dt,
                sls_sales,
                sls_quantity,
                sls_price
            )
        select
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            CASE
                WHEN sls_ord_dt = 0
                or LEN(sls_ord_dt) != 8 THEN NULL
                ELSE cast(CAST(sls_ord_dt AS VARCHAR) as date)
            END as sls_order_date,
            CASE
                WHEN sls_ship_dt = 0
                or LEN(sls_ship_dt) != 8 THEN NULL
                ELSE cast(CAST(sls_ship_dt AS VARCHAR) as date)
            END as sls_ship_dt,
            CASE
                WHEN sls_due_dt = 0
                or LEN(sls_due_dt) != 8 THEN NULL
                ELSE cast(CAST(sls_due_dt AS VARCHAR) as date)
            END as sls_due_date,
            CASE
                WHEN sls_sales is NULL
                or sls_sales <= 0
                or sls_sales != sls_quantity * abs(sls_price) THEN sls_quantity * abs(sls_price)
                ELSE sls_sales
            end as sls_sales,
            sls_quantity,
            CASE
                WHEN sls_price is NULL
                or sls_price <= 0 THEN sls_sales / nullif(sls_quantity, 0)
                ELSE sls_price
            end as sls_price
        from
            bronze.crm_sales_details;
        set @end_time = GETDATE();
        print 'Load Duration: ' + cast(DATEDIFF(SECOND,@start_time,@end_time) as NVARCHAR) + ' seconds';
        print '>>--------------------';


        print'-----------------------------------------------';
        print'Loading ERP Tables';
        print'-----------------------------------------------';

        set @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_CUST_AZ12' TRUNCATE TABLE silver.erp_CUST_AZ12 PRINT '>> Inserting Data Into: silver.erp_CUST_AZ12'
        insert into
            silver.erp_CUST_AZ12 (cid, bdate, gen)
        SELECT
            CASE
                WHEN cid like 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
                else cid
            end as cid,
            CASE
                WHEN bdate > GETDATE() THEN NULL
                else bdate
            end bdate,
            case
                WHEN UPPER(TRIM(gen)) in ('F', 'Female') then 'Female'
                WHEN UPPER(TRIM(gen)) in ('M', 'Male') then 'Male'
                else 'n/a'
            end as gen
        from
            bronze.erp_CUST_AZ12;
        set @end_time = GETDATE();
        print 'Load Duration: ' + cast(DATEDIFF(SECOND,@start_time,@end_time) as NVARCHAR) + ' seconds';
        print '>>--------------------';

        set @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_LOC_A101' TRUNCATE TABLE silver.erp_LOC_A101 PRINT '>> Inserting Data Into: silver.erp_LOC_A101'
        INSERT into
            silver.erp_LOC_A101 (cid, cntry)
        SELECT
            REPLACE(cid, '-', '') as cid,
            case
                when TRIM(cntry) = 'DE' THEN 'Germany'
                WHEN TRIM(cntry) in ('US', 'USA') THEN 'United States'
                WHEN TRIM(cntry) = ''
                or cntry is null then 'n/a'
                else TRIM(cntry)
            end as cntry
        from
            bronze.erp_LOC_A101;
        set @end_time = GETDATE();
        print 'Load Duration: ' + cast(DATEDIFF(SECOND,@start_time,@end_time) as NVARCHAR) + ' seconds';
        print '>>--------------------';

        set @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_PX_CAT_G1V2' TRUNCATE TABLE silver.erp_PX_CAT_G1V2 PRINT '>> Inserting Data Into: silver.erp_PX_CAT_G1V2'
        INSERT into
            silver.erp_PX_CAT_G1V2 (id, cat, subcat, MAINTENANCE)
        SELECT
            id,
            cat,
            subcat,
            MAINTENANCE
        from
            bronze.erp_PX_CAT_G1V2;
        set @end_time = GETDATE();
        print 'Load Duration: ' + cast(DATEDIFF(SECOND,@start_time,@end_time) as NVARCHAR) + ' seconds';
        print '>>--------------------';

        set @batch_end_time = GETDATE();
        print '============================================';
        print 'Loading Bronze Layer Is Completed';
        print 'Total Load Duration ' + cast(DATEDIFF(SECOND,@batch_start_time,@batch_end_time) as NVARCHAR) +' seconds'; 
        print '============================================';
    end try 
    begin CATCH
        print '===============================================';
        print 'ERROR OCURRED DURING LOADING BRONZE LAYER';
        Print 'Error Message: ' + error_message();
        print 'Error Number: ' + cast(error_number() as NVARCHAR);
        PRINT 'Error State: ' + cast(error_state() as NVARCHAR);
        print '===============================================';
    end CATCH
END
