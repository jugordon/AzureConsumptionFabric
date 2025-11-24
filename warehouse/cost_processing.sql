CREATE OR ALTER PROCEDURE cost.cost_processing @period INT
AS
BEGIN
    DECLARE @datePeriod DATE = DATEADD(MONTH, @period, GETDATE());
    DECLARE @ayer DATE = DATEADD(DAY, -1, GETDATE());
    DECLARE @diasRestantesMesActual INT = DATEDIFF(DAY, @ayer, EOMONTH(@ayer));

    IF @period BETWEEN -12 AND 0
    BEGIN
        --------------------------------------------------------------------
        -- 1. Limpiar datos del periodo a procesar
        --------------------------------------------------------------------
        DELETE FROM cost.consumoAzure_agg WHERE YEAR(fecha) = YEAR(@datePeriod) AND MONTH(fecha) = MONTH(@datePeriod);
        DELETE FROM cost.consumoAzure_agg_databricks WHERE YEAR(fecha) = YEAR(@datePeriod) AND MONTH(fecha) = MONTH(@datePeriod);
        DELETE FROM cost.consumoAzure_comparativo_historico;
        DELETE FROM cost.consumoAzure_agg_storage;
        DELETE FROM cost.consumoAzure_databricks_comparativo_historico;


        --------------------------------------------------------------------
        -- 2. Insertar datos en tabla de datos agregados, aqui se necesitan configurar las etiquetas a extraer 
        --------------------------------------------------------------------
        INSERT INTO cost.consumoAzure_agg
        SELECT 
            [Date] AS [fecha],
            [SubscriptionId] AS [suscripcionID],
            [SubscriptionName] AS [suscripcion],
            [ResourceLocation] AS [region],
            [UnitOfMeasure] AS [UnidadDeMedida],
            [UnitOfMeasureNumeric] AS [UnidadDeMedidaNumerica],
            [ResourceGroup] AS [grupoRecursos],
            [MeterCategory] AS [categoriaProducto],
            [MeterSubCategory] AS [subCategoriaProducto],
            [ProductName] AS [producto],
            [ResourceName] AS [IdInstancia],
            JSON_VALUE([AdditionalInfo], '$.ServiceType') AS [ServiceType],
            JSON_VALUE([AdditionalInfo], '$.ImageType') AS [ImageType],
            JSON_VALUE([AdditionalInfo], '$.VCPUs') AS [VCPUs],
            SUM([CostInBillingCurrency]) AS [ACR],
            SUM([Quantity]) AS [cantidadConsumida],
            [ChargeType] AS [ChargeType],
            -- Modificar para extraer el Proyecto desde la columna Tags con las diferentes variantes posibles de nombres --
            CASE
                WHEN JSON_VALUE(CONCAT('{', [Tags], ' }'), '$.Solucion') IS NOT NULL THEN JSON_VALUE(CONCAT('{', [Tags], ' }'), '$.Solucion')
                WHEN JSON_VALUE(CONCAT('{', [Tags], ' }'), '$."proyecto"') IS NOT NULL THEN JSON_VALUE(CONCAT('{', [Tags], ' }'), '$."proyecto"')
                WHEN JSON_VALUE(CONCAT('{', [Tags], ' }'), '$."Proyecto"') IS NOT NULL THEN JSON_VALUE(CONCAT('{', [Tags], ' }'), '$."Proyecto"')
                ELSE JSON_VALUE(CONCAT('{', [Tags], ' }'), '$."Servicio"')
            END AS [Proyecto],
            JSON_VALUE(CONCAT('{', [Tags], ' }'), '$.Ambiente') AS [Ambiente]
        FROM cost.consumoAzure
        WHERE YEAR([Date]) = YEAR(@datePeriod) AND MONTH([Date]) = MONTH(@datePeriod)
        GROUP BY [Date],[SubscriptionId],[SubscriptionName],[ResourceLocation],[UnitOfMeasure],[UnitOfMeasureNumeric],[ResourceGroup],
                 [MeterCategory],[MeterSubCategory],[ProductName],[ResourceName],[ChargeType],
                 JSON_VALUE([AdditionalInfo], '$.ServiceType'),
                 JSON_VALUE([AdditionalInfo], '$.ImageType'),
                 JSON_VALUE([AdditionalInfo], '$.VCPUs'),
                 --- Por cada variacion de nombres de tags se debe de agregar un elemento en el group by
                 JSON_VALUE(CONCAT('{', [Tags], ' }'), '$.Solucion'),
                 JSON_VALUE(CONCAT('{', [Tags], ' }'), '$."proyecto"'),
                 JSON_VALUE(CONCAT('{', [Tags], ' }'), '$."Proyecto"'),
                 JSON_VALUE(CONCAT('{', [Tags], ' }'), '$."Servicio"'),
                 JSON_VALUE(CONCAT('{', [Tags], ' }'), '$.Ambiente');

        --------------------------------------------------------------------
        -- 3. Comparativo histórico
        --------------------------------------------------------------------
        INSERT INTO cost.consumoAzure_comparativo_historico
        SELECT 
            [suscripcion] as [suscripcion],
            [categoriaProducto] as [categoriaProducto],
            [ChargeType] as [ChargeType],
            [grupoRecursos] as [grupoRecursos],
            DATEFROMPARTS(YEAR([fecha]), MONTH([fecha]), 1) AS [anioMes],
            SUM([ACR]) + CASE WHEN DATEFROMPARTS(YEAR([fecha]), MONTH([fecha]), 1) = DATEFROMPARTS(YEAR(@ayer), MONTH(@ayer), 1)
                              THEN (SUM([ACR]) / DAY(@ayer)) * @diasRestantesMesActual ELSE 0 END AS [consumoActual],
            LAG(SUM([ACR]), 1, 0) OVER (PARTITION BY [suscripcion],[categoriaProducto],[ChargeType],[grupoRecursos] ORDER BY DATEFROMPARTS(YEAR([fecha]), MONTH([fecha]), 1)) AS [consumoMesAnterior],
            (SUM([ACR]) + CASE WHEN DATEFROMPARTS(YEAR([fecha]), MONTH([fecha]), 1) = DATEFROMPARTS(YEAR(@ayer), MONTH(@ayer), 1)
                               THEN (SUM([ACR]) / DAY(@ayer)) * @diasRestantesMesActual ELSE 0 END)
            - LAG(SUM([ACR]), 1, 0) OVER (PARTITION BY [suscripcion],[categoriaProducto],[ChargeType],[grupoRecursos] ORDER BY DATEFROMPARTS(YEAR([fecha]), MONTH([fecha]), 1)) AS [DiferenciaConsumo],
            @diasRestantesMesActual AS [diasRestantesMesActual]
        FROM cost.consumoAzure_agg
        WHERE [fecha] >= DATEADD(YEAR, -2, GETDATE()) AND [ChargeType] = 'Usage'
        GROUP BY [suscripcion],[categoriaProducto],[ChargeType],[grupoRecursos],DATEFROMPARTS(YEAR([fecha]), MONTH([fecha]), 1);

        --------------------------------------------------------------------
        -- 4. Tabla Storage 
        --------------------------------------------------------------------
        INSERT INTO cost.consumoAzure_agg_storage
        SELECT 
            DATEFROMPARTS(YEAR(t1.[fecha]), MONTH(t1.[fecha]), 1) AS [anioMes],
            t1.[IdInstancia] AS [IdInstancia],
            t1.[subCategoriaProducto] AS [subCategoriaProducto],
            t1.[suscripcionID] AS [suscriptionID],
            t1.[suscripcion] AS [suscriptionName],
            t1.[grupoRecursos] AS [grupoRecursos],
            t1.[UnidadDeMedida] AS [unidadMedida],
            t1.[Proyecto] AS [proyecto],
            SUM(t1.[ACR]) AS [ACR],
            SUM(t1.[cantidadConsumida]) AS [cantidadConsumida],
            t1.[UnidadDeMedidaNumerica] as unidadMedidaNumerica,
            0 as [cantidadAlmacenada]
        FROM cost.consumoAzure_agg t1
        WHERE t1.[categoriaProducto] = 'Storage' AND t1.[producto] LIKE '%Data Stored%'
        GROUP BY DATEFROMPARTS(YEAR(t1.[fecha]), MONTH(t1.[fecha]), 1), t1.[IdInstancia], t1.[subCategoriaProducto], t1.[suscripcionID], t1.[suscripcion], t1.[grupoRecursos], t1.[UnidadDeMedida], t1.[Proyecto],t1.[UnidadDeMedidaNumerica];

        update cost.consumoAzure_agg_storage
        set cantidadAlmacenada = cantidadConsumida / (unidadMedidaNumerica + 0.0)
        where cantidadConsumida > 0 and unidadMedida LIKE '%GB%';

        update cost.consumoAzure_agg_storage
        set cantidadAlmacenada = (cantidadConsumida * 1024) / (unidadMedidaNumerica + 0.0)
        where cantidadConsumida > 0 and unidadMedida LIKE '%TB%';

        --------------------------------------------------------------------
        -- 5. Tabla Databricks
        --------------------------------------------------------------------
        INSERT INTO cost.consumoAzure_agg_databricks
        SELECT 
            cs.[Date] AS [fecha],
            cs.[SubscriptionId] AS [suscripcionID],
            cs.[SubscriptionName] AS [suscripcionNombre],
            cs.[ResourceGroup] AS [grupoRecursos],
            cs.[MeterCategory] AS [categoriaProducto],
            cs.[MeterSubCategory] AS [subCategoriaProducto],
            cs.[ProductName] AS [producto],
            cs.[ResourceName] AS [IdInstancia],
            cs.[ChargeType] AS [ChargeType],
            JSON_VALUE(CONCAT('{', cs.[Tags], ' }'), '$.ClusterName') AS [ClusterName],
            JSON_VALUE(CONCAT('{', cs.[Tags], ' }'), '$.JobId') AS [JobId],
            JSON_VALUE(CONCAT('{', cs.[Tags], ' }'), '$.DatabricksEnvironment') AS [DatabricksEnvironment],
            JSON_VALUE(CONCAT('{', cs.[Tags], ' }'), '$.RunName') AS [RunName],
            JSON_VALUE(CONCAT('{', cs.[Tags], ' }'), '$.Application_Name') AS [proyecto],
            CASE WHEN JSON_VALUE(CONCAT('{', cs.[Tags], ' }'), '$.JobId') IS NOT NULL THEN 'Job' ELSE 'Interactivo' END AS [TipoCluster],
            SUM(cs.[CostInBillingCurrency]) AS [ACR],
            SUM(cs.[Quantity]) AS [cantidadConsumida]
        FROM cost.consumoAzure cs
        WHERE YEAR(cs.[Date]) = YEAR(@datePeriod) AND MONTH(cs.[Date]) = MONTH(@datePeriod)
          AND ISJSON(CONCAT('{', cs.[Tags], ' }')) > 0
          AND cs.[MeterCategory] = 'Azure Databricks'
        GROUP BY cs.[Date], cs.[SubscriptionId], cs.[SubscriptionName], cs.[ResourceGroup], cs.[MeterCategory], cs.[MeterSubCategory], cs.[ProductName], cs.[ResourceName], cs.[ChargeType],
                 JSON_VALUE(CONCAT('{', cs.[Tags], ' }'), '$.ClusterName'),
                 JSON_VALUE(CONCAT('{', cs.[Tags], ' }'), '$.JobId'),
                 JSON_VALUE(CONCAT('{', cs.[Tags], ' }'), '$.DatabricksEnvironment'),
                 JSON_VALUE(CONCAT('{', cs.[Tags], ' }'), '$.RunName'),
                 JSON_VALUE(CONCAT('{', cs.[Tags], ' }'), '$.Application_Name')

        --------------------------------------------------------------------
        -- 6. Comparativo Databricks
        --------------------------------------------------------------------
        INSERT INTO cost.consumoAzure_databricks_comparativo_historico
        SELECT 
            cs.[suscripcionID],
            cs.[suscripcionNombre],
            cs.[IdInstancia] AS [Workspace],
            cs.[categoriaProducto],
            DATEFROMPARTS(YEAR(cs.[fecha]), MONTH(cs.[fecha]), 1) AS [anioMes],
            SUM(cs.[ACR]) + CASE WHEN DATEFROMPARTS(YEAR(cs.[fecha]), MONTH(cs.[fecha]), 1) = DATEFROMPARTS(YEAR(@ayer), MONTH(@ayer), 1)
                                 THEN (SUM(cs.[ACR]) / DAY(@ayer)) * @diasRestantesMesActual ELSE 0 END AS [consumoActual],
            LAG(SUM(cs.[ACR]), 1, 0) OVER (PARTITION BY cs.[suscripcionID], cs.[suscripcionNombre], cs.[IdInstancia], cs.[categoriaProducto] ORDER BY DATEFROMPARTS(YEAR(cs.[fecha]), MONTH(cs.[fecha]), 1)) AS [consumoMesAnterior],
            (SUM(cs.[ACR]) + CASE WHEN DATEFROMPARTS(YEAR(cs.[fecha]), MONTH(cs.[fecha]), 1) = DATEFROMPARTS(YEAR(@ayer), MONTH(@ayer), 1)
                                  THEN (SUM(cs.[ACR]) / DAY(@ayer)) * @diasRestantesMesActual ELSE 0 END)
            - LAG(SUM(cs.[ACR]), 1, 0) OVER (PARTITION BY cs.[suscripcionID], cs.[suscripcionNombre], cs.[IdInstancia], cs.[categoriaProducto] ORDER BY DATEFROMPARTS(YEAR(cs.[fecha]), MONTH(cs.[fecha]), 1)) AS [DiferenciaConsumo],
            @diasRestantesMesActual AS [diasRestantesMesActual]
        FROM cost.consumoAzure_agg_databricks cs
        WHERE cs.[fecha] >= DATEADD(YEAR, -2, GETDATE()) AND cs.[ChargeType] = 'Usage' AND cs.[categoriaProducto] = 'Azure Databricks'
        GROUP BY cs.[suscripcionID], cs.[suscripcionNombre], cs.[IdInstancia], cs.[categoriaProducto], DATEFROMPARTS(YEAR(cs.[fecha]), MONTH(cs.[fecha]), 1);
    END
    ELSE
       BEGIN
        SELECT 'Invalid period - Should be between -3 and 0'
        END 
    END;
