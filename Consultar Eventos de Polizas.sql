SELECT	po.ReferenciaNumerica, po.Fecha, po.ID_Poliza, CONCAT(po.ID_Evento, '-', TRIM(ev.ClaveEvento), '-', ev.Descripcion) AS Evento, po.Concepto,
		pd.ID_PolizaDetalle, pd.Cargo, pd.Abono,
		CONCAT(cu.ID_Cuenta,'-', TRIM(tc.ClaveTipoCuenta),'-', tc.Descripcion) Cuenta,
		CONCAT(co.ID_Colectiva, '-', co.ClaveColectiva, '-', co.NombreORazonSocial) Colectiva
FROM	dbo.Poliza po
LEFT	JOIN dbo.PolizaDetalle pd ON pd.ID_Poliza = po.ID_Poliza
LEFT	JOIN dbo.Colectivas co ON co.ID_Colectiva = pd.ID_Colectiva
LEFT	JOIN dbo.Cuentas cu ON cu.ID_Cuenta = pd.ID_Cuenta
LEFT	JOIN dbo.TipoCuenta tc ON tc.ID_TipoCuenta = cu.ID_TipoCuenta
LEFT	JOIN dbo.Eventos ev ON ev.ID_Evento = po.ID_Evento
WHERE	po.ID_Operacion IN(223650)
ORDER BY pd.ID_PolizaDetalle;

--Retiro ATM sin los cambios Empresa-Subempresa
--SELECT * FROM dbo.Operaciones WHERE Autorizacion = '001870';