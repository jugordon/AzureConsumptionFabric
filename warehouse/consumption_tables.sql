
---Ejecutar de forma inicial creacion del schema --
Create schema cost;



CREATE TABLE [cost].[consumoAzure]
(
	[InvoiceSectionName] [varchar](200) NULL,
	[AccountName] [varchar](200) NULL,
	[AccountOwnerId] [varchar](200) NULL,
	[SubscriptionId] [varchar](200) NULL,
	[SubscriptionName] [varchar](200) NULL,
	[ResourceGroup] [varchar](200) NULL,
	[ResourceLocation] [varchar](200) NULL,
	[Date] [date] NULL,
	[ProductName] [varchar](500) NULL,
	[MeterCategory] [varchar](300) NULL,
	[MeterSubCategory] [varchar](300) NULL,
	[MeterId] [varchar](200) NULL,
	[MeterName] [varchar](200) NULL,
	[MeterRegion] [varchar](200) NULL,
	[UnitOfMeasure] [varchar](200) NULL,
	[Quantity] [real] NULL,
	[EffectivePrice] [real] NULL,
	[CostInBillingCurrency] [real] NULL,
	[CostCenter] [varchar](200) NULL,
	[ConsumedService] [varchar](200) NULL,
	[ResourceId] [varchar](1000) NULL,
	[Tags] [varchar](max) NULL,
	[OfferId] [varchar](200) NULL,
	[AdditionalInfo] [varchar](max) NULL,
	[ServiceInfo1] [varchar](200) NULL,
	[ServiceInfo2] [varchar](200) NULL,
	[ResourceName] [varchar](200) NULL,
	[ReservationId] [varchar](200) NULL,
	[ReservationName] [varchar](200) NULL,
	[UnitPrice] [real] NULL,
	[ProductOrderId] [varchar](200) NULL,
	[ProductOrderName] [varchar](200) NULL,
	[Term] [varchar](200) NULL,
	[PublisherType] [varchar](200) NULL,
	[PublisherName] [varchar](200) NULL,
	[ChargeType] [varchar](200) NULL,
	[Frequency] [varchar](200) NULL,
	[PricingModel] [varchar](200) NULL,
	[AvailabilityZone] [varchar](200) NULL,
	[BillingAccountId] [varchar](200) NULL,
	[BillingAccountName] [varchar](200) NULL,
	[BillingCurrencyCode] [varchar](200) NULL,
	[BillingPeriodStartDate] [varchar](200) NULL,
	[BillingPeriodEndDate] [varchar](200) NULL,
	[BillingProfileId] [varchar](200) NULL,
	[BillingProfileName] [varchar](200) NULL,
	[InvoiceSectionId] [varchar](200) NULL,
	[IsAzureCreditEligible] [varchar](200) NULL,
	[PartNumber] [varchar](200) NULL,
	[PayGPrice] [real] NULL,
	[PlanName] [varchar](200) NULL,
	[ServiceFamily] [varchar](200) NULL,
	[CostAllocationRuleName] [varchar](200) NULL,
	[benefitId] [varchar](200) NULL,
	[benefitName] [varchar](200) NULL,
	[UnitOfMeasureNumeric] [int] NULL
);

CREATE TABLE [cost].[consumoAzure_agg]
(
	[fecha] [date] NULL,
	[suscripcionID] [varchar](150) NULL,
	[suscripcion] [varchar](200) NULL,
	[region] [varchar](200) NULL,
	[UnidadDeMedida] [varchar](200) NULL,
	[UnidadDeMedidaNumerica] [int] NULL,
	[grupoRecursos] [varchar](150) NULL,
	[categoriaProducto] [varchar](300) NULL,
	[subCategoriaProducto] [varchar](300) NULL,
	[producto] [varchar](500) NULL,
	[IdInstancia] [varchar](200) NULL,
	[ServiceType] [varchar](4000) NULL,
	[ImageType] [varchar](4000) NULL,
	[VCPUs] [varchar](4000) NULL,
	[ACR] [float] NULL,
	[cantidadConsumida] [float] NULL,
	[ChargeType] [varchar](150) NULL,
	[Proyecto] [varchar](4000) NULL,
	[Ambiente] [varchar](4000) NULL
);

CREATE TABLE [cost].[consumoAzure_agg_databricks]
(
	[fecha] [date] NULL,
	[suscripcionID] [varchar](200) NULL,
	[suscripcionNombre] [varchar](200) NULL,
	[grupoRecursos] [varchar](200) NULL,
	[categoriaProducto] [varchar](300) NULL,
	[subCategoriaProducto] [varchar](300) NULL,
	[producto] [varchar](500) NULL,
	[IdInstancia] [varchar](max) NULL,
	[ChargeType] [varchar](200) NULL,
	[ClusterName] [varchar](max) NULL,
	[JobId] [varchar](max) NULL,
	[DatabricksEnvironment] [varchar](300) NULL,
	[RunName] [varchar](max) NULL,
	[proyecto] [varchar](300) NULL,
	[TipoCluster] [varchar](50) NULL,
	[ACR] [float] NULL,
	[cantidadConsumida] [float] NULL
);

CREATE TABLE [cost].[consumoAzure_agg_storage]
(
	[anioMes] [date] NULL,
	[IdInstancia] [varchar](200) NULL,
	[subCategoriaProducto] [varchar](300) NULL,
	[suscriptionID] [varchar](200) NULL,
	[suscriptionName] [varchar](200) NULL,
	[grupoRecursos] [varchar](200) NULL,
	[unidadMedida] [varchar](200) NULL,
	[proyecto] [varchar](4000) NULL,
	[ACR] [float] NULL,
	[cantidadConsumida] [float] NULL,
	[unidadMedidaNumerica] [int] NOT NULL,
	[cantidadAlmacenada] [float] NULL
);

CREATE TABLE [cost].[consumoAzure_comparativo_historico]
(
	[suscripcion] [varchar](200) NULL,
	[categoriaProducto] [varchar](300) NULL,
	[ChargeType] [varchar](200) NULL,
	[grupoRecursos] [varchar](200) NULL,
	[anioMes] [date] NULL,
	[consumoActual] [float] NULL,
	[consumoMesAnterior] [float] NULL,
	[DiferenciaConsumo] [float] NULL,
	[diasRestantesMesActual] [int] NOT NULL
);

CREATE TABLE [cost].[consumoAzure_databricks_comparativo_historico]
(
	[suscripcionID] [varchar](200) NULL,
	[suscripcionNombre] [varchar](200) NULL,
	[Workspace] [varchar](200) NULL,
	[categoriaProducto] [varchar](300) NULL,
	[anioMes] [date] NULL,
	[consumoActual] [float] NULL,
	[consumoMesAnterior] [float] NULL,
	[DiferenciaConsumo] [float] NULL,
	[diasRestantesMesActual] [int] NOT NULL
);