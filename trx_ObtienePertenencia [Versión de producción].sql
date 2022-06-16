USE AUTO_CACAO
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO

--SELECT * FROM dbo.PlugIns
-- Stored Procedure

-- =============================================        
-- Author:  LUIS DE LA TORRE        
-- Create date: 12 FEBRERO 2011        
-- Description: OBTIENE EL IDENTIFICADOR DE LA PERTENENCIA DE UNA OPERACION A PARTIR DE SIUS VALORES DE REFERENCIA        
-- =============================================        
/*        

declare @p11 bigint        
exec trx_ObtienePertenencia N'12341234567890123456',N'TAR',N'MXN',N'EMISOR',N'143100',N'7654321',N'0200',@p11 output        
select  @p11        

         spEjecutor.registerOutParameter ( "@ID_TipoCuenta", Types.INTEGER ) ;    
            spEjecutor.registerOutParameter ( "@ID_MA", Types.INTEGER ) ;    
*/    
CREATE   PROCEDURE  [dbo].[trx_ObtienePertenencia]
    @MedioAcceso VARCHAR(50) ,
    @TipoMedioAcceso VARCHAR(10) ,
    @CodigoMoneda VARCHAR(3) ,
    @Beneficiario VARCHAR(25) ,
    @ProcessingCode VARCHAR(6) ,
    @Afiliacion VARCHAR(20) ,
    @TipoMensaje VARCHAR(4) ,
    @POSEM VARCHAR(5) ,
    @PIN VARCHAR(10) ,
    @PointService VARCHAR(20) ,
    @FunctionCode VARCHAR(20) = NULL ,
    @PlugInInstancia VARCHAR(50) ,
    @DraftCaptureFlag INT ,
    @ID_Pertenencia BIGINT OUTPUT ,
    @ID_Emisor INT OUTPUT ,
    @ID_CadenaComercial INT OUTPUT ,
    @ID_GrupoCuenta INT OUTPUT ,
    @ID_GrupoMA INT OUTPUT ,
    @ID_GrupoComercial INT OUTPUT ,
    @ID_CuentaHabiente INT OUTPUT ,
    @ID_TarjetaHabiente INT OUTPUT ,
    @ClaveTarjetaHabiente VARCHAR(50) OUTPUT ,
    @ID_PadreDeCuentahabiente INT = 0 OUTPUT ,
    @ID_AbueloDeCuentahabiente INT = 0 OUTPUT ,
    @ID_TipoCuenta INT = 0 OUTPUT ,
    @ID_MA INT = 0 OUTPUT
    WITH ENCRYPTION
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	--select * from Colectivas where ID_TipoColectiva=4
	--SET @ID_CadenaComercial = 6322
	--SET @ID_CuentaHabiente = 5556
	--SET @ID_Pertenencia = 379
	--SET @ID_Emisor = 10
	--RETURN    

	--  WAITFOR DELAY '00:20:20'      

	--SELECT * FROM dbo.PolizaDetalle ORDER BY ID_PolizaDetalle desc    

        SET NOCOUNT ON;        
        DECLARE @TipoCuenta INT;        
        DECLARE @reg INT;      
        DECLARE @TienePIN BIT;    
        DECLARE @ERROR2 VARCHAR(1000);    

        IF LEN(@PIN) < 4
            BEGIN
                SET @TienePIN = 0;
            END;
        ELSE
            BEGIN
                SET @TienePIN = 1;
            END; 

	--Obtiene la Colectiva Cadena y la colectiva Grupo Comercial        
        SELECT TOP 1 
	      -- @ID_CadenaComercial = ISNULL(CADENA.ID_Colectiva, 0),
                @ID_GrupoComercial = ISNULL(GRUPO.ID_Colectiva, 0)
        FROM    Colectivas GRUPO WITH (NOLOCK)
                INNER JOIN Colectivas CADENA WITH (NOLOCK)
                    ON CADENA.ID_ColectivaPadre = GRUPO.ID_Colectiva
                INNER JOIN Colectivas SUCURSAL WITH (NOLOCK)
                    ON SUCURSAL.ID_ColectivaPadre = CADENA.ID_Colectiva
                INNER JOIN Colectivas AFILIACION WITH (NOLOCK)
                    ON AFILIACION.ID_ColectivaPadre = SUCURSAL.ID_Colectiva
        WHERE   AFILIACION.ClaveColectiva = @Afiliacion
                AND AFILIACION.ID_TipoColectiva = 1;    

        SELECT TOP (1)
                @ID_CadenaComercial = ISNULL(col.ID_ColectivaPadre, 0)
        FROM    Colectivas col WITH (NOLOCK)
                INNER JOIN ColectivaMedioAcceso cMe WITH (NOLOCK)
                    ON (col.ID_Colectiva = cMe.ID_Colectiva)
                INNER JOIN MediosAcceso med WITH (NOLOCK)
                    ON (cMe.ID_MA = med.ID_MA)
        WHERE   med.ClaveMA = @MedioAcceso
                AND med.ID_TipoMA = 1;



        IF @ID_CadenaComercial = 0
            OR @ID_CadenaComercial IS NULL
            BEGIN
                DECLARE @ERROR VARCHAR(500);    
                SET @ERROR = '[trx_ObtienePertenencia] -LA AFILIACION NO ESTA REGISTRADA EN LA BD ['
                    + CONVERT(VARCHAR(20), @Afiliacion)
                    + '], O BIEN NO ES CORRECTA LA RELACION ENTRE COLECTIVAS';

                RAISERROR(@ERROR, 16, 1); 
                RETURN;
            END;    

        SET @ID_Emisor = 10;    


        SELECT  @ClaveTarjetaHabiente = ISNULL(ClaveColectiva, '') ,
                @ID_MA = MediosAcceso.ID_MA
        FROM    dbo.Colectivas WITH (NOLOCK)
                INNER JOIN dbo.ColectivaMedioAcceso WITH (NOLOCK)
                    ON dbo.Colectivas.ID_Colectiva = dbo.ColectivaMedioAcceso.ID_Colectiva
                INNER JOIN dbo.MediosAcceso WITH (NOLOCK)
                    ON dbo.ColectivaMedioAcceso.ID_MA = dbo.MediosAcceso.ID_MA
                INNER JOIN dbo.TipoMedioAcceso WITH (NOLOCK)
                    ON dbo.MediosAcceso.ID_TipoMA = dbo.TipoMedioAcceso.ID_TipoMA
        WHERE   MediosAcceso.ClaveMA = @MedioAcceso
                AND TipoMedioAcceso.Clave = @TipoMedioAcceso;         

        SET @ClaveTarjetaHabiente = ISNULL(@ClaveTarjetaHabiente, '');    


        SELECT  @ID_GrupoMA = ISNULL(ma.ID_GrupoMA, 0) ,
                @TipoCuenta = ISNULL(CodTipoCuentaISO, 0) ,
                @ID_GrupoCuenta = ISNULL(gc.ID_GrupoCuenta, 0) ,
                @ID_Emisor = ISNULL(gc.ID_ColectivaEmisor, 0) ,
                @ID_CuentaHabiente = ISNULL(c.ID_ColectivaCuentahabiente, 0) ,
                @ID_TarjetaHabiente = 0 ,	--ISNULL(CMA.ID_Colectiva, 0)      
                @ID_TipoCuenta = ISNULL(c.ID_TipoCuenta, 0)
        FROM    Cuentas c WITH (NOLOCK)
                INNER JOIN GruposCuenta gc WITH (NOLOCK)
                    ON c.ID_GrupoCuenta = gc.ID_GrupoCuenta
                INNER JOIN TipoCuenta tc WITH (NOLOCK)
                    ON c.ID_TipoCuenta = tc.ID_TipoCuenta
                INNER JOIN MediosAccesoCuenta mac WITH (NOLOCK)
                    ON mac.ID_Cuenta = c.ID_Cuenta
                INNER JOIN MediosAcceso ma WITH (NOLOCK)
                    ON mac.ID_MA = ma.ID_MA
                INNER JOIN TipoMedioAcceso tma WITH (NOLOCK)
                    ON tma.ID_TipoMA = ma.ID_TipoMA 
	                --INNER JOIN ColectivaMedioAcceso CMA ON CMA.ID_MA = ma.ID_MA
        WHERE   tc.CodTipoCuentaISO = SUBSTRING(@ProcessingCode, 3, 2)
                AND c.ID_ColectivaCadenaComercial = @ID_CadenaComercial
                AND ma.ClaveMA = @MedioAcceso
                AND tma.Clave = @TipoMedioAcceso;        


        IF @ID_GrupoCuenta = 0
            OR @ID_GrupoCuenta IS NULL
            BEGIN
                SELECT  @ID_GrupoMA = ISNULL(ma.ID_GrupoMA, 0) ,
                        @TipoCuenta = ISNULL(CodTipoCuentaISO, 0) ,
                        @ID_GrupoCuenta = ISNULL(gc.ID_GrupoCuenta, 0) ,
                        @ID_Emisor = ISNULL(gc.ID_ColectivaEmisor, 0) ,
                        @ID_CuentaHabiente = ISNULL(c.ID_ColectivaCuentahabiente,
                                                    0) ,
                        @ID_TarjetaHabiente = 0 ,	--ISNULL(CMA.ID_Colectiva, 0)  
                        @ID_TipoCuenta = ISNULL(c.ID_TipoCuenta, 0)
                FROM    Cuentas c WITH (NOLOCK)
                        INNER JOIN GruposCuenta gc WITH (NOLOCK)
                            ON c.ID_GrupoCuenta = gc.ID_GrupoCuenta
                        INNER JOIN TipoCuenta tc WITH (NOLOCK)
                            ON c.ID_TipoCuenta = tc.ID_TipoCuenta
                        INNER JOIN MediosAccesoCuenta mac WITH (NOLOCK)
                            ON mac.ID_Cuenta = c.ID_Cuenta
                        INNER JOIN MediosAcceso ma WITH (NOLOCK)
                            ON mac.ID_MA = ma.ID_MA
                        INNER JOIN TipoMedioAcceso tma WITH (NOLOCK)
                            ON tma.ID_TipoMA = ma.ID_TipoMA 
	                    --INNER JOIN ColectivaMedioAcceso CMA ON CMA.ID_MA = ma.ID_MA
                WHERE   tc.CodTipoCuentaISO = SUBSTRING(@ProcessingCode, 3, 2)
                        AND c.ID_ColectivaCadenaComercial IS NULL
                        AND ma.ClaveMA = @MedioAcceso
                        AND tma.Clave = @TipoMedioAcceso;
            END; 

	--SI NO ENCUENTRA EL TIPO DE CUENTA QUE VIENE EN EL CODIGO DE PROCESO, ENTONCES TOMA UNA POR DEFAULT.    
        IF @ID_GrupoCuenta = 0
            OR @ID_GrupoCuenta IS NULL
            BEGIN
                SELECT TOP 1
                        @ID_GrupoMA = ISNULL(ma.ID_GrupoMA, 0) ,
                        @TipoCuenta = ISNULL(CodTipoCuentaISO, 0) ,
                        @ID_GrupoCuenta = ISNULL(gc.ID_GrupoCuenta, 0) ,
                        @ID_Emisor = ISNULL(gc.ID_ColectivaEmisor, 0) ,
                        @ID_CuentaHabiente = ISNULL(c.ID_ColectivaCuentahabiente,
                                                    0) ,
                        @ID_TarjetaHabiente = 0 ,	--ISNULL(CMA.ID_Colectiva, 0)   
                        @ID_TipoCuenta = ISNULL(c.ID_TipoCuenta, 0)
                FROM    Cuentas c WITH (NOLOCK)
                        INNER JOIN GruposCuenta gc WITH (NOLOCK)
                            ON c.ID_GrupoCuenta = gc.ID_GrupoCuenta
                        INNER JOIN TipoCuenta tc WITH (NOLOCK)
                            ON c.ID_TipoCuenta = tc.ID_TipoCuenta
                        INNER JOIN MediosAccesoCuenta mac WITH (NOLOCK)
                            ON mac.ID_Cuenta = c.ID_Cuenta
                        INNER JOIN MediosAcceso ma WITH (NOLOCK)
                            ON mac.ID_MA = ma.ID_MA
                        INNER JOIN TipoMedioAcceso tma WITH (NOLOCK)
                            ON tma.ID_TipoMA = ma.ID_TipoMA
                WHERE   ma.ClaveMA = @MedioAcceso
                        AND tma.Clave = @TipoMedioAcceso
                ORDER BY tc.CodTipoCuentaISO ASC;    


                SELECT  @ID_GrupoMA = ISNULL(ID_GrupoMA, 0)
                FROM    MediosAcceso WITH (NOLOCK)
                        INNER JOIN TipoMedioAcceso tma WITH (NOLOCK)
                            ON tma.ID_TipoMA = MediosAcceso.ID_TipoMA
                WHERE   ClaveMA = @MedioAcceso
                        AND tma.Clave = @TipoMedioAcceso;    

                IF @ID_GrupoMA = 0
                    OR @ID_GrupoMA IS NULL
                    BEGIN
	        --RAISERROR( 'NO HAY UN GRUPO DE MEDIO DE ACCESO ESPEFICICADO',16,1)
	        --          RETURN      
                        SET @ID_GrupoMA = 18;
                    END;    

                IF @PlugInInstancia = 'isoPlugInEFECTPOS'
                    BEGIN
	        --IF EXISTS ( SELECT  *
	        --            FROM    MediosAcceso
	        --            WHERE   ClaveMA = @MedioAcceso )
	        --    BEGIN    

                        SET @ID_Emisor = 10;    

                        SELECT  @ID_Pertenencia = ISNULL(ID_Pertenencia, 0)
                        FROM    Pertenencia pe WITH (NOLOCK)
                        WHERE   pe.CodigoProceso = @ProcessingCode
                                AND pe.TipoMensaje = @TipoMensaje
                                AND pe.Beneficiario = @Beneficiario
                                AND pe.ClaveAfiliacion = @Afiliacion
                                AND pe.ID_GrupoMA = @ID_GrupoMA
                                AND @POSEM LIKE pe.POSEM
                                AND EsActiva = 1; 

                        RETURN; 

	        --    END
	        --ELSE
	        --    BEGIN    

	        --        SELECT  @ID_Pertenencia = ISNULL(ID_Pertenencia, 0)
	        --        FROM    Pertenencia pe
	        --        WHERE   pe.CodigoProceso = @ProcessingCode
	        --                AND pe.TipoMensaje = @TipoMensaje
	        --                AND pe.Beneficiario = @Beneficiario
	        --                AND pe.ClaveAfiliacion = @Afiliacion
	        --                 AND PE.ID_GrupoMA is null
	        --                 AND @POSEM LIKE pe.POSEM
	        --                and EsActiva=1
	        --        RETURN ;
	        --    END
                    END;
                ELSE
                    BEGIN
                        IF @ID_GrupoCuenta = 0
                            OR @ID_GrupoCuenta IS NULL
                            BEGIN
	            --DECLARE @ERROR2 VARCHAR(500)      
                                SET @ERROR2 = '[trx_ObtienePertenencia] -EL MEDIO DE ACCESO ['
                                    + @MedioAcceso + ',' + @TipoMedioAcceso
                                    + '] NO TIENE CUENTA DEL TIPO ['
                                    + SUBSTRING(@ProcessingCode, 3, 2)
                                    + '] PARA LA CADENA '
                                    + CONVERT(VARCHAR(20), @ID_CadenaComercial);

                                RAISERROR(@ERROR2, 16, 1); 
                                RETURN;
                            END;
                    END;      

                IF @ID_GrupoCuenta = 0
                    OR @ID_GrupoCuenta IS NULL
                    BEGIN
	        --DECLARE @ERROR2 VARCHAR(500)    
                        SET @ERROR2 = '[trx_ObtienePertenencia] -EL MEDIO DE ACCESO ['
                            + @MedioAcceso + ',' + @TipoMedioAcceso
                            + '] NO TIENE CUENTA DEL TIPO ['
                            + SUBSTRING(@ProcessingCode, 3, 2)
                            + '] PARA LA CADENA '
                            + CONVERT(VARCHAR(20), @ID_CadenaComercial);

                        RAISERROR(@ERROR2, 16, 1); 
                        RETURN;
                    END;
            END; 


	--OBTIENE EL PADRE Y ABUELO DEL CUENTAHABEINTE A NIEVEL RELACION ECONOMICA (LA RELACION PADRE-HIJO EN COLECTIVAS ES EXCLUSIVA DE RELACIONES DE JERARQUIAS)    

        SELECT  @ID_PadreDeCuentahabiente = ISNULL(PADRE.ID_ColectivaPadre, 0) ,
                @ID_AbueloDeCuentahabiente = ISNULL(ABUELO.ID_Colectiva, 0)
        FROM    dbo.RelacionPadresColectivas PADRE WITH (NOLOCK)
                LEFT JOIN dbo.RelacionPadresColectivas ABUELO WITH (NOLOCK)
                    ON PADRE.ID_ColectivaPadre = ABUELO.ID_Colectiva
        WHERE   PADRE.ID_Colectiva = @ID_CuentaHabiente; 


	--SI EL PADRE O ABUELO ES NULL ENTONCES POR DEFUAL DNU ES EL PAPÁ O ABUELO O AMBAS.    
        IF @ID_PadreDeCuentahabiente IS NULL
            OR @ID_PadreDeCuentahabiente = 0
            BEGIN
                SELECT  @ID_PadreDeCuentahabiente = ISNULL(dbo.Colectivas.ID_Colectiva,
                                                           0)
                FROM    dbo.Colectivas WITH (NOLOCK)
                WHERE   ClaveColectiva = 'CADDNU';
            END;    

        IF @ID_AbueloDeCuentahabiente IS NULL
            OR @ID_AbueloDeCuentahabiente = 0
            BEGIN
                SELECT  @ID_AbueloDeCuentahabiente = ISNULL(dbo.Colectivas.ID_Colectiva,
                                                            0)
                FROM    dbo.Colectivas WITH (NOLOCK)
                WHERE   ClaveColectiva = 'CADDNU';
            END; 



	--OBTIENE LA PERTENENCIA DE ACUERDO AL PLUGIN DE ENTRADA     
        IF @PlugInInstancia = 'isoPlugInEVERTEC'
            OR @PlugInInstancia = 'isoPlugInEVERTEC_CL'
			  OR @PlugInInstancia = 'isoEvertecLATAM'
			  OR @PlugInInstancia = 'isoEvertecHNL'
			  OR @PlugInInstancia = 'isoEvertecSLV'
            BEGIN
                SELECT  @ID_Pertenencia = ISNULL(ID_Pertenencia, 0)
                FROM    Pertenencia pe WITH (NOLOCK)
                WHERE   pe.ClaveAfiliacion = @Afiliacion 
	           --AND pe.Beneficiario = @Beneficiario
                        AND pe.CodigoProceso = @ProcessingCode
                        AND pe.TipoMensaje = @TipoMensaje
                        AND pe.ID_GrupoMA = @ID_GrupoMA 
	               -- AND pe.TipoCuentaISO = SUBSTRING(@ProcessingCode, 3, 2)
                        AND pe.ID_GrupoCuenta = @ID_GrupoCuenta 
	               -- And moneda = @CodigoMoneda
	               --AND pe.ID_ColectivaEmisor = @ID_Emisor
                        AND @POSEM LIKE LTRIM(RTRIM(pe.POSEM));
	    -- AND DraftCaptureFlag = @DraftCaptureFlag
	    --AND @TienePIN = pe.PIN    

                IF @ID_Pertenencia = 0
                    OR @ID_Pertenencia IS NULL
                    BEGIN
                        SET @ERROR = '[trx_ObtienePertenencia] -NO HAY RELACIONES DE PERTENENCIA ' 
	            -- + ', TienePIN =' + CONVERT(VARCHAR(20), @TienePIN)    
                            + ', POSEM =' + CONVERT(VARCHAR(20), @POSEM) 
	            -- + ', DraftCaputreFlag ='                             + CONVERT(VARCHAR(20), @DraftCaptureFlag)    
                            + ', ClaveAfiliacion ='
                            + CONVERT(VARCHAR(20), @Afiliacion) 
	            --+ ', Beneficiario ='                              + CONVERT(VARCHAR(20), @Beneficiario)    
                            + ', CodigoProceso ='
                            + CONVERT(VARCHAR(20), @ProcessingCode)
                            + ', TipoMensaje ='
                            + CONVERT(VARCHAR(20), @TipoMensaje)
                            + ', ID_GrupoMA ='
                            + CONVERT(VARCHAR(20), @ID_GrupoMA) 
	            -- + ', TipoCuentaISO ='                              + CONVERT(VARCHAR(20), @TipoCuenta)    
                            + ', ID_GrupoCuenta ='
                            + CONVERT(VARCHAR(20), @ID_GrupoCuenta) 
	            -- + ', ID_ColectivaEmisor ='                             + CONVERT(VARCHAR(20), @ID_Emisor)       
                            + ', moneda ='
                            + CONVERT(VARCHAR(20), @CodigoMoneda); 

                        RAISERROR(@ERROR, 16, 1); 
                        RETURN;
                    END;
            END;
        ELSE
            IF @PlugInInstancia = 'isoPlugInPROSAPOS'
                BEGIN
                    SELECT  @ID_Pertenencia = ISNULL(ID_Pertenencia, 0)
                    FROM    Pertenencia pe WITH (NOLOCK)
                    WHERE   pe.ClaveAfiliacion = @Afiliacion 
	           --AND pe.Beneficiario = @Beneficiario
                            AND pe.CodigoProceso = @ProcessingCode
                            AND pe.TipoMensaje = @TipoMensaje
                            AND pe.ID_GrupoMA = @ID_GrupoMA 
	               -- AND pe.TipoCuentaISO = SUBSTRING(@ProcessingCode, 3, 2)
                            AND pe.ID_GrupoCuenta = @ID_GrupoCuenta 
	               --AND pe.ID_ColectivaEmisor = @ID_Emisor
                            AND @POSEM LIKE pe.POSEM
                            AND DraftCaptureFlag = @DraftCaptureFlag
                            AND @TienePIN = pe.PIN;    

                    IF @ID_Pertenencia = 0
                        OR @ID_Pertenencia IS NULL
                        BEGIN
                            SET @ERROR = '[trx_ObtienePertenencia] -NO HAY RELACIONES DE PERTENENCIA '
                                + ', TienePIN ='
                                + CONVERT(VARCHAR(20), @TienePIN)
                                + ', POSEM =' + CONVERT(VARCHAR(20), @POSEM)
                                + ', DraftCaputreFlag ='
                                + CONVERT(VARCHAR(20), @DraftCaptureFlag)
                                + ', ClaveAfiliacion ='
                                + CONVERT(VARCHAR(20), @Afiliacion)
                                + ', Beneficiario ='
                                + CONVERT(VARCHAR(20), @Beneficiario)
                                + ', CodigoProceso ='
                                + CONVERT(VARCHAR(20), @ProcessingCode)
                                + ', TipoMensaje ='
                                + CONVERT(VARCHAR(20), @TipoMensaje)
                                + ', ID_GrupoMA ='
                                + CONVERT(VARCHAR(20), @ID_GrupoMA)
                                + ', TipoCuentaISO ='
                                + CONVERT(VARCHAR(20), @TipoCuenta)
                                + ', ID_GrupoCuenta ='
                                + CONVERT(VARCHAR(20), @ID_GrupoCuenta)
                                + ', ID_ColectivaEmisor ='
                                + CONVERT(VARCHAR(20), @ID_Emisor); 

                            RAISERROR(@ERROR, 16, 1); 
                            RETURN;
                        END;
                END;
            ELSE
                IF @PlugInInstancia = 'isoPlugInPROSAATM'
                    BEGIN
                        SELECT  @ID_Pertenencia = ISNULL(ID_Pertenencia, 0)
                        FROM    Pertenencia pe WITH (NOLOCK)
                        WHERE   pe.ClaveAfiliacion = @Afiliacion 
	           --AND pe.Beneficiario = @Beneficiario
                                AND pe.CodigoProceso = @ProcessingCode
                                AND pe.TipoMensaje = @TipoMensaje
                                AND pe.ID_GrupoMA = @ID_GrupoMA 
	               --  AND pe.TipoCuentaISO = SUBSTRING(@ProcessingCode,
	               --                                 3, 2)
                                AND pe.ID_GrupoCuenta = @ID_GrupoCuenta 
	               -- AND pe.ID_ColectivaEmisor = @ID_Emisor
                                AND @POSEM LIKE pe.POSEM
                                AND DraftCaptureFlag = @DraftCaptureFlag
                                AND @TienePIN = pe.PIN;    

                        IF @ID_Pertenencia = 0
                            OR @ID_Pertenencia IS NULL
                            BEGIN
                                SET @ERROR = '[trx_ObtienePertenencia] -NO HAY RELACIONES DE PERTENENCIA '
                                    + ', TienePIN ='
                                    + CONVERT(VARCHAR(20), @TienePIN)
                                    + ', POSEM ='
                                    + CONVERT(VARCHAR(20), @POSEM)
                                    + ', DraftCaputreFlag ='
                                    + CONVERT(VARCHAR(20), @DraftCaptureFlag)
                                    + ', ClaveAfiliacion ='
                                    + CONVERT(VARCHAR(20), @Afiliacion)
                                    + ', Beneficiario ='
                                    + CONVERT(VARCHAR(20), @Beneficiario)
                                    + ', CodigoProceso ='
                                    + CONVERT(VARCHAR(20), @ProcessingCode)
                                    + ', TipoMensaje ='
                                    + CONVERT(VARCHAR(20), @TipoMensaje)
                                    + ', ID_GrupoMA ='
                                    + CONVERT(VARCHAR(20), @ID_GrupoMA)
                                    + ', TipoCuentaISO ='
                                    + CONVERT(VARCHAR(20), @TipoCuenta)
                                    + ', ID_GrupoCuenta ='
                                    + CONVERT(VARCHAR(20), @ID_GrupoCuenta)
                                    + ', ID_ColectivaEmisor ='
                                    + CONVERT(VARCHAR(20), @ID_Emisor); 

                                RAISERROR(@ERROR, 16, 1); 
                                RETURN;
                            END;
                    END;
                ELSE
                    IF @PlugInInstancia = 'isoPlugInMCPOS'
                        BEGIN
                            SELECT  @ID_Pertenencia = ISNULL(ID_Pertenencia, 0)
                            FROM    Pertenencia pe WITH (NOLOCK)
                            WHERE   --pe.ClaveAfiliacion = @Afiliacion
	           --AND pe.Beneficiario = @Beneficiario    
	           /*AND */             pe.CodigoProceso = @ProcessingCode
                                    AND pe.TipoMensaje = @TipoMensaje
                                    AND pe.ID_GrupoMA = @ID_GrupoMA 
	               --AND pe.TipoCuentaISO = SUBSTRING(@ProcessingCode,
	               --                              3, 2)
                                    AND pe.ID_GrupoCuenta = @ID_GrupoCuenta
                                    AND pe.ID_ColectivaEmisor = @ID_Emisor
                                    AND @POSEM LIKE pe.POSEM
                                    AND @PointService LIKE pe.PointService
                                    AND @TienePIN = pe.PIN;    

                            IF @ID_Pertenencia = 0
                                OR @ID_Pertenencia IS NULL
                                BEGIN
                                    SET @ERROR = '[trx_ObtienePertenencia] -NO HAY RELACIONES DE PERTENENCIA '
                                        + ', TienePIN ='
                                        + CONVERT(VARCHAR(20), @TienePIN)
                                        + ', POSEM ='
                                        + CONVERT(VARCHAR(20), @POSEM)
                                        + ', PointService ='
                                        + CONVERT(VARCHAR(20), @pointservice)
                                        + ', ClaveAfiliacion ='
                                        + CONVERT(VARCHAR(20), @Afiliacion)
                                        + ', Beneficiario ='
                                        + CONVERT(VARCHAR(20), @Beneficiario)
                                        + ', CodigoProceso ='
                                        + CONVERT(VARCHAR(20), @ProcessingCode)
                                        + ', TipoMensaje ='
                                        + CONVERT(VARCHAR(20), @TipoMensaje)
                                        + ', ID_GrupoMA ='
                                        + CONVERT(VARCHAR(20), @ID_GrupoMA)
                                        + ', TipoCuentaISO ='
                                        + CONVERT(VARCHAR(20), @TipoCuenta)
                                        + ', ID_GrupoCuenta ='
                                        + CONVERT(VARCHAR(20), @ID_GrupoCuenta)
                                        + ', ID_ColectivaEmisor ='
                                        + CONVERT(VARCHAR(20), @ID_Emisor); 

                                    RAISERROR(@ERROR, 16, 1); 
                                    RETURN;
                                END;
                        END;
                    ELSE
                        IF @PlugInInstancia = 'isoPlugInMCATM'
                            BEGIN
                                SELECT  @ID_Pertenencia = ISNULL(ID_Pertenencia,
                                                              0)
                                FROM    Pertenencia pe WITH (NOLOCK)
                                WHERE   --pe.ClaveAfiliacion = @Afiliacion
	           --AND pe.Beneficiario = @Beneficiario    
	           /*AND */                 pe.CodigoProceso = @ProcessingCode
                                        AND pe.TipoMensaje = @TipoMensaje
                                        AND pe.ID_GrupoMA = @ID_GrupoMA 
	               --AND pe.TipoCuentaISO = SUBSTRING(@ProcessingCode,
	               --                          3, 2)
                                        AND pe.ID_GrupoCuenta = @ID_GrupoCuenta
                                        AND pe.ID_ColectivaEmisor = @ID_Emisor
                                        AND @POSEM LIKE pe.POSEM
                                        AND @PointService LIKE pe.PointService
                                        AND @TienePIN = pe.PIN;    

                                IF @ID_Pertenencia = 0
                                    OR @ID_Pertenencia IS NULL
                                    BEGIN
                                        SET @ERROR = '[trx_ObtienePertenencia] -NO HAY RELACIONES DE PERTENENCIA '
                                            + ', TienePIN ='
                                            + CONVERT(VARCHAR(20), @TienePIN)
                                            + ', POSEM ='
                                            + CONVERT(VARCHAR(20), @POSEM)
                                            + ', PointService ='
                                            + CONVERT(VARCHAR(20), @pointservice)
                                            + ', ClaveAfiliacion ='
                                            + CONVERT(VARCHAR(20), @Afiliacion)
                                            + ', Beneficiario ='
                                            + CONVERT(VARCHAR(20), @Beneficiario)
                                            + ', CodigoProceso ='
                                            + CONVERT(VARCHAR(20), @ProcessingCode)
                                            + ', TipoMensaje ='
                                            + CONVERT(VARCHAR(20), @TipoMensaje)
                                            + ', ID_GrupoMA ='
                                            + CONVERT(VARCHAR(20), @ID_GrupoMA)
                                            + ', TipoCuentaISO ='
                                            + CONVERT(VARCHAR(20), @TipoCuenta)
                                            + ', ID_GrupoCuenta ='
                                            + CONVERT(VARCHAR(20), @ID_GrupoCuenta)
                                            + ', ID_ColectivaEmisor ='
                                            + CONVERT(VARCHAR(20), @ID_Emisor); 

                                        RAISERROR(@ERROR, 16, 1); 
                                        RETURN;
                                    END;
                            END;
                        ELSE
                            IF @PlugInInstancia = 'isoPlugInMCCLRING'
                                BEGIN
                                    SELECT  @ID_Pertenencia = ISNULL(ID_Pertenencia,
                                                              0)
                                    FROM    Pertenencia pe WITH (NOLOCK)
                                    WHERE   pe.TipoMensaje = @TipoMensaje
                                            AND FunctionCode = @FunctionCode;    



                                    IF @ID_Pertenencia = 0
                                        OR @ID_Pertenencia IS NULL
                                        BEGIN
                                            SET @ERROR = '[trx_ObtienePertenencia] -NO HAY RELACIONES DE PERTENENCIA '
                                                + ', TipoMensaje ='
                                                + CONVERT(VARCHAR(20), @TipoMensaje)
                                                + ', FunctionCode ='
                                                + CONVERT(VARCHAR(20), @FunctionCode); 


                                            RAISERROR(@ERROR, 16, 1); 
                                            RETURN;
                                        END;
                                END;
                            ELSE
                                IF @PlugInInstancia = 'isoPlugInISO2003'
                                    BEGIN
                                        SELECT  @ID_Pertenencia = ISNULL(ID_Pertenencia,
                                                              0)
                                        FROM    Pertenencia pe WITH (NOLOCK)
                                        WHERE   pe.ClaveAfiliacion = @Afiliacion
                                                AND pe.Beneficiario = @Beneficiario
                                                AND pe.CodigoProceso = @ProcessingCode
                                                AND pe.TipoMensaje = @TipoMensaje
                                                AND pe.ID_GrupoMA = @ID_GrupoMA 
	               --AND pe.TipoCuentaISO = SUBSTRING(@ProcessingCode,
	               --                  3, 2)
                                                AND pe.ID_GrupoCuenta = @ID_GrupoCuenta
                                                AND pe.ID_ColectivaEmisor = @ID_Emisor
                                                AND @POSEM LIKE pe.POSEM
                                                AND @PointService LIKE pe.PointService
                                                AND pe.POSEM = @POSEM;
                                    END;
    END;
GO
