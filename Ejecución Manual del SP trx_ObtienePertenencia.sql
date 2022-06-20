DECLARE @ID_Pertenencia BIGINT ,
		@ID_Emisor INT ,
		@ID_CadenaComercial INT ,
		@ID_GrupoCuenta INT ,
		@ID_GrupoMA INT ,
		@ID_GrupoComercial INT ,
		@ID_CuentaHabiente INT ,
		@ID_TarjetaHabiente INT ,
		@ClaveTarjetaHabiente VARCHAR(50) ,
		@ID_PadreDeCuentahabiente INT = 0 ,
		@ID_AbueloDeCuentahabiente INT = 0 ,
		@ID_TipoCuenta INT = 0 ,
		@ID_MA INT = 0;

EXEC [dbo].[trx_ObtienePertenencia]
    @MedioAcceso		= '9900012036066218' ,
    @TipoMedioAcceso	= 'TAR',
    @CodigoMoneda		= '484',
    @Beneficiario		= '',
    @ProcessingCode		= '010000',
    @Afiliacion			= '4000001',
    @TipoMensaje		= '0200',
    @POSEM				= '',
    @PIN				= '1234',
    @PointService		= '0000000',
    @FunctionCode		= NULL ,
    @PlugInInstancia	= NULL,
    @DraftCaptureFlag	= 0,
    @ID_Pertenencia				= @ID_Pertenencia OUTPUT ,
    @ID_Emisor					= @ID_Emisor OUTPUT ,
    @ID_CadenaComercial			= @ID_CadenaComercial OUTPUT ,
    @ID_GrupoCuenta				= @ID_GrupoCuenta OUTPUT ,
    @ID_GrupoMA					= @ID_GrupoMA OUTPUT ,
    @ID_GrupoComercial			= @ID_GrupoComercial OUTPUT ,
    @ID_CuentaHabiente			= @ID_CuentaHabiente OUTPUT ,
    @ID_TarjetaHabiente			= @ID_TarjetaHabiente OUTPUT ,
    @ClaveTarjetaHabiente		= @ClaveTarjetaHabiente OUTPUT ,
    @ID_PadreDeCuentahabiente	= @ID_PadreDeCuentahabiente OUTPUT ,
    @ID_AbueloDeCuentahabiente	= @ID_AbueloDeCuentahabiente OUTPUT ,
    @ID_TipoCuenta				= @ID_TipoCuenta OUTPUT ,
    @ID_MA						= @ID_MA OUTPUT;

SELECT
	@ID_Pertenencia				AS [@ID_Pertenencia],
    @ID_Emisor					AS [@ID_Emisor],
    @ID_CadenaComercial			AS [@ID_CadenaComercial],
    @ID_GrupoCuenta				AS [@ID_GrupoCuenta],
    @ID_GrupoMA					AS [@ID_GrupoMA],
    @ID_GrupoComercial			AS [@ID_GrupoComercial],
    @ID_CuentaHabiente			AS [@ID_CuentaHabiente],
    @ID_TarjetaHabiente			AS [@ID_TarjetaHabiente],
    @ClaveTarjetaHabiente		AS [@ClaveTarjetaHabiente],
    @ID_PadreDeCuentahabiente	AS [@ID_PadreDeCuentahabiente],
    @ID_AbueloDeCuentahabiente	AS [@ID_AbueloDeCuentahabiente],
    @ID_TipoCuenta				AS [@ID_TipoCuenta],
    @ID_MA						AS [@ID_MA];


	--SELECT c.ID_Colectiva as padre, ID_ColectivaPadre as abuelo, * FROM dbo.Producto p INNER JOIN dbo.Colectivas c on c.ID_Colectiva = p.ID_Colectiva WHERE p.ID_GrupoCuenta = 1159
	--select * from dbo.MediosAcceso m inner join MediosAccesoCuenta c on c.ID_MA = m.ID_MA inner join Cuentas cu on cu.ID_Cuenta = c.ID_Cuenta WHERE m.ClaveMA = '9900012000270009'
	--SELECT * FROM dbo.TipoProducto where ID_TipoProducto = 4

	--SELECT	*
	--		--p.ID_Colectiva, 
	--		--c.ID_ColectivaPadre
	--FROM	dbo.Producto p WITH(nolock)
	--INNER	JOIN dbo.Colectivas c WITH(nolock)
	--	on c.ID_Colectiva = p.ID_Colectiva 
	--WHERE	p.ID_GrupoCuenta IN(1603,1159);
