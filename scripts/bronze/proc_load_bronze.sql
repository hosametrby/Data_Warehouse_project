/*
================================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
================================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files.
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
================================================================================
*/
create or alter procedure bronze.load_bronze as
begin
    DECLARE @start_time DATETIME , @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
    begin try 
        set @batch_start_time = GETDATE();
        print '==============================================';
        print 'Loading Bronze Layer';
        print '==============================================';


        print'-----------------------------------------------';
        print'Loading CRM Tables';
        print'-----------------------------------------------';


        set @start_time = GETDATE();
        print '>> Truncating Table: bronze.crm_cust_info';
        truncate table bronze.crm_cust_info;

        print '>> Inserting data into: bronze.crm_cust_info'
        bulk insert bronze.crm_cust_info
        from 'C:\Users\hossa\Desktop\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
        with(
            firstrow = 2,
            fieldterminator= ',',
            tablock
        );
        set @end_time = GETDATE();
        print 'Load Duration: ' + cast(DATEDIFF(SECOND,@start_time,@end_time) as NVARCHAR) + ' seconds';
        print '>>--------------------';

        set @start_time = GETDATE();
        print '>> Truncating Table: bronze.crm_prd_info';
        truncate table bronze.crm_prd_info;

        print '>> Inserting data into: bronze.crm_prd_info'
        bulk insert bronze.crm_prd_info
        from 'C:\Users\hossa\Desktop\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
        with(
            firstrow = 2,
            fieldterminator= ',',
            tablock
        );
        SET @end_time = GETDATE();
        print 'Load Duration: ' + cast(DATEDIFF(SECOND,@start_time,@end_time) as NVARCHAR) + ' seconds';
        print '>>--------------------';

        set @start_time = GETDATE();
        print '>> Truncating Table: bronze.crm_sales_details';
        truncate table bronze.crm_sales_details;

        print '>> Inserting data into: bronze.crm_sales_details'
        bulk insert bronze.crm_sales_details
        from 'C:\Users\hossa\Desktop\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
        with(
            firstrow = 2,
            fieldterminator= ',',
            tablock
        );
        set @end_time = GETDATE();
        print 'Load Duration: ' + cast(DATEDIFF(SECOND,@start_time,@end_time) as NVARCHAR) + ' seconds';
        print '>>--------------------';


        print'-----------------------------------------------';
        print'Loading ERP Tables';
        print'-----------------------------------------------';


        set @start_time = GETDATE();
        print '>> Truncating Table: bronze.erp_cust_az12'
        truncate table bronze.erp_cust_az12;

        print '>> Inserting data into: bronze.erp_cust_az12'
        bulk insert bronze.erp_cust_az12
        from 'C:\Users\hossa\Desktop\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
        with(
            firstrow = 2,
            fieldterminator= ',',
            tablock
        );
        set @end_time = GETDATE();
        print 'Load Duration: ' + cast(DATEDIFF(SECOND,@start_time,@end_time) as NVARCHAR) + ' seconds';
        print '>>--------------------';


        set @start_time = GETDATE();
        print '>> Truncating Table: bronze.erp_loc_a101'
        truncate table bronze.erp_loc_a101;

        print '>> Inserting data into:bronze.erp_loc_a101'
        bulk insert bronze.erp_loc_a101
        from 'C:\Users\hossa\Desktop\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
        with(
            firstrow = 2,
            fieldterminator= ',',
            tablock
        );
        set @end_time = GETDATE();
        print 'Load Duration: ' + cast(DATEDIFF(SECOND,@start_time,@end_time) as NVARCHAR) + ' seconds';
        print '>>--------------------';


        set @start_time = GETDATE();
        print '>> Truncating Table: bronze.erp_PX_CAT_G1V2'
        truncate table bronze.erp_PX_CAT_G1V2;

        print '>> Inserting data into:bronze.erp_PX_CAT_G1V2'
        bulk insert bronze.erp_PX_CAT_G1V2
        from 'C:\Users\hossa\Desktop\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
        with(
            firstrow = 2,
            fieldterminator= ',',
            tablock
        );
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
end
