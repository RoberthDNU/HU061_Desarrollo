USE AUTO_CACAO;
GO

DECLARE @ID_PadreDeCuentahabiente INT = 0, @ID_AbueloDeCuentahabiente INT = 0, @Cuentahabiente INT = 211783;

--OBTIENE EL PADRE Y ABUELO DEL CUENTAHABEINTE A NIEVEL RELACION ECONOMICA (LA RELACION PADRE-HIJO EN COLECTIVAS ES EXCLUSIVA DE RELACIONES DE JERARQUIAS)    
SELECT  @ID_PadreDeCuentahabiente = ISNULL(PADRE.ID_ColectivaPadre, 0) ,
        @ID_AbueloDeCuentahabiente = ISNULL(ABUELO.ID_Colectiva, 0)
FROM    dbo.RelacionPadresColectivas PADRE WITH (NOLOCK)
        LEFT JOIN dbo.RelacionPadresColectivas ABUELO WITH (NOLOCK)
            ON PADRE.ID_ColectivaPadre = ABUELO.ID_Colectiva
WHERE   PADRE.ID_Colectiva = @Cuentahabiente; 

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

	SELECT @ID_PadreDeCuentahabiente AS [@ID_PadreDeCuentahabiente], @ID_AbueloDeCuentahabiente AS [@ID_AbueloDeCuentahabiente];

	--NUEVAS VALIDACIONES
IF (@ID_PadreDeCuentahabiente IS NOT NULL AND @ID_PadreDeCuentahabiente <> 0)
	BEGIN
	--CAMBIOS A REALIZAR
	--1) SI @ID_PADRE ES SUB-EMPRESA [LUIS]
	--		OBTENER ABUELO Y BISABUELO DE @ID_PADRE
	--		SET @PADRE = ABUELO DEL @ID_PADRE
	--		SET @ABUELO = BISABUELO DEL @ID_PADRE
	IF(SELECT ClaveTipoColectiva FROM TipoColectiva tp INNER JOIN Colectivas col ON tp.ID_TipoColectiva = col.ID_TipoColectiva WHERE col.ID_Colectiva = @ID_PadreDeCuentahabiente ) ='SUC' 
		BEGIN
				SELECT  @ID_PadreDeCuentahabiente = ISNULL(BISABUELO.ID_ColectivaPadre, 0),
						@ID_AbueloDeCuentahabiente =  ISNULL(TATARABUELO.ID_ColectivaPadre, 0)
						--@ID_BisabueloDeCuentahabiente = ISNULL(BISABUELO.ID_ColectivaPadre, 0),
						--@ID_TatarabueloDeCuentahabiente = ISNULL(TATARABUELO.ID_ColectivaPadre, 0)
				FROM    dbo.Colectivas PADRE WITH (NOLOCK)
						INNER JOIN dbo.Colectivas ABUELO WITH (NOLOCK)
							ON ABUELO.ID_Colectiva = PADRE.ID_ColectivaPadre 
						INNER JOIN dbo.Colectivas BISABUELO WITH (NOLOCK)
							ON BISABUELO.ID_Colectiva = ABUELO.ID_ColectivaPadre
						INNER JOIN dbo.Colectivas TATARABUELO WITH (NOLOCK)
							ON TATARABUELO.ID_Colectiva = BISABUELO.ID_ColectivaPadre
				WHERE   PADRE.ID_Colectiva = @Cuentahabiente;
		END
	--2) SI @ID_PADRE ES EMPRESA [ROBERTO]
	--		OBTENER PADRE Y ABUELO DE @ID_PADRE
	--		SET @PADRE = PADRE DEL @ID_PADRE
	--		SET @ABUELO = ABUELO DEL @ID_PADRE
	IF (SELECT	tc.ClaveTipoColectiva
		FROM	dbo.Colectivas c 
		LEFT	JOIN dbo.TipoColectiva tc ON tc.ID_TipoColectiva = c.ID_TipoColectiva
		WHERE	c.ID_Colectiva IN(@ID_PadreDeCuentahabiente)) = 'CCM'
		BEGIN
			SELECT @ID_PadreDeCuentahabiente = ID_ColectivaPadre FROM dbo.Colectivas PADRE WITH(nolock) WHERE PADRE.ID_Colectiva = @ID_PadreDeCuentahabiente;
			SELECT @ID_AbueloDeCuentahabiente = ID_ColectivaPadre FROM dbo.Colectivas PADRE WITH(nolock) WHERE PADRE.ID_Colectiva = @ID_PadreDeCuentahabiente;
			SELECT @ID_PadreDeCuentahabiente AS [@ID_PadreDeCuentahabiente], @ID_AbueloDeCuentahabiente AS [@ID_AbueloDeCuentahabiente];
		END
	--3) SI @ID_PADRE ES CLIENTE CACAO [SESIÓN ZOOM]
	--		OBTENER PADRE DE @ID_PADRE
	--		SET @ABUELO = PADRE DE @ID_PADRE
	IF ((SELECT	tc.ClaveTipoColectiva
		FROM	dbo.Colectivas c 
		LEFT	JOIN dbo.TipoColectiva tc ON tc.ID_TipoColectiva = c.ID_TipoColectiva
		WHERE	c.ID_Colectiva IN(@ID_PadreDeCuentahabiente)) = 'GCM')
		BEGIN
			SELECT @ID_AbueloDeCuentahabiente = ID_ColectivaPadre FROM dbo.Colectivas PADRE WITH(nolock) WHERE PADRE.ID_Colectiva = @ID_PadreDeCuentahabiente;
			SELECT @ID_PadreDeCuentahabiente AS [@ID_PadreDeCuentahabiente], @ID_AbueloDeCuentahabiente AS [@ID_AbueloDeCuentahabiente];
		END
	END


/* QUERY QUE REVISA LOS TIPOS DE COLECTIVA
SELECT	c.ID_Colectiva, c.ClaveColectiva, 
		CONCAT(c.NombreORazonSocial, ' ', c.APaterno, ' ', c.AMaterno) RazonSocial,
		CONCAT(c.ID_ColectivaPadre, ' ', c2.NombreORazonSocial, ' ', c2.APaterno, ' ', c2.AMaterno) ColectivaPadre,
		CONCAT(c.ID_TipoColectiva, '-', tc.ClaveTipoColectiva,'-', tc.Descripcion) TipoColectiva
FROM	dbo.Colectivas c 
LEFT	JOIN dbo.TipoColectiva tc ON tc.ID_TipoColectiva = c.ID_TipoColectiva
LEFT	JOIN dbo.Colectivas c2 ON c2.ID_Colectiva = c.ID_ColectivaPadre
WHERE	c.ID_Colectiva IN(7821, 5683, 10);
*/
--DATOS DE PRUEBA
--211785 TH de Subempresa
--211783 TH de Empresa