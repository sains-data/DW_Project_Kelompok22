-- Test Advanced Analytics Views
-- PT XYZ Data Warehouse - Advanced Analytics Validation
-- Date: 2025-05-24

USE PTXYZ_DataWarehouse;
GO

PRINT '🔍 Testing Advanced Analytics Views';
PRINT '=====================================';

-- Test 1: Executive Dashboard View
PRINT '';
PRINT '1. Testing Executive Dashboard View...';
BEGIN TRY
    SELECT TOP 5 * FROM analytics.vw_ExecutiveDashboard
    ORDER BY MonthYear DESC;
    PRINT '✅ Executive Dashboard View - SUCCESS';
END TRY
BEGIN CATCH
    PRINT '❌ Executive Dashboard View - ERROR: ' + ERROR_MESSAGE();
END CATCH

-- Test 2: Real-Time Operations View
PRINT '';
PRINT '2. Testing Real-Time Operations View...';
BEGIN TRY
    SELECT TOP 5 * FROM analytics.vw_RealTimeOperations;
    PRINT '✅ Real-Time Operations View - SUCCESS';
END TRY
BEGIN CATCH
    PRINT '❌ Real-Time Operations View - ERROR: ' + ERROR_MESSAGE();
END CATCH

-- Test 3: Predictive Insights View
PRINT '';
PRINT '3. Testing Predictive Insights View...';
BEGIN TRY
    SELECT TOP 5 * FROM analytics.vw_PredictiveInsights
    ORDER BY MonthYear DESC;
    PRINT '✅ Predictive Insights View - SUCCESS';
END TRY
BEGIN CATCH
    PRINT '❌ Predictive Insights View - ERROR: ' + ERROR_MESSAGE();
END CATCH

-- Test 4: Cost Optimization View
PRINT '';
PRINT '4. Testing Cost Optimization View...';
BEGIN TRY
    SELECT TOP 5 * FROM analytics.vw_CostOptimization
    ORDER BY MonthYear DESC;
    PRINT '✅ Cost Optimization View - SUCCESS';
END TRY
BEGIN CATCH
    PRINT '❌ Cost Optimization View - ERROR: ' + ERROR_MESSAGE();
END CATCH

-- Test 5: Performance Test
PRINT '';
PRINT '5. Performance Testing...';
DECLARE @StartTime DATETIME2 = SYSDATETIME();

-- Test complex query performance
SELECT 
    COUNT(*) as ExecutiveDashboardRows,
    DATEDIFF(MILLISECOND, @StartTime, SYSDATETIME()) as ExecutionTimeMs
FROM analytics.vw_ExecutiveDashboard;

SET @StartTime = SYSDATETIME();
SELECT 
    COUNT(*) as PredictiveInsightsRows,
    DATEDIFF(MILLISECOND, @StartTime, SYSDATETIME()) as ExecutionTimeMs
FROM analytics.vw_PredictiveInsights;

PRINT '✅ Performance Testing Complete';

PRINT '';
PRINT '🎯 Advanced Analytics Views Testing Complete!';
