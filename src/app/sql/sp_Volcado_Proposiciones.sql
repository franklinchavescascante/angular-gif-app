USE [PIN]
GO
/****** Object:  StoredProcedure [dbo].[sp_Volcado_Proposiciones]    Script Date: 23/8/2024 09:41:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  StoredProcedure [dbo].[sp_Volcado_Proposiciones]    Script Date: 26/08/2016 02:25:11 p.m. ******/
ALTER PROCEDURE [dbo].[sp_Volcado_Proposiciones] @TC_Tipo_Volcado AS VARCHAR(20),
 												 @TC_Fecha_Inicial AS DATETIME,
												 @TC_Fecha_Final AS DATETIME,
												 @TC_Cod_Usuario as varchar(30) AS

/*** STORE PROCEDURE PARA EL VOLCADO DE PROPOSICIONES A SIGA ***/
/*** HECHO POR ALBERTO ROJAS NARANJO 
*		MODIFICADO POR LUIS QUESADA MENDEZ - 21 DE ABRIL DEL 2009    -> ARREGLO PARA QUE EL VOLCADO NO DE ERRORES CUANDO INGRESA COMPONENTES ICS FUERA DEL RANDO (ICS CON RANGO VOLCADO)
*					   LUIS QUESADA MENDEZ - 24 DE ABRIL DEL 2009    -> INSERCCION DE LOS TRACTOS 2, 3 Y 4 DEL ICS
*                      CÉLIMO ELIZONDO AGUILAR - 02 DE MAYO DEL 2013 -> SE CREA VOLCADO DE LAS PROPOSICIONES DE LA TERNA ELECTRÓNICA
*					   MANUEL DIAZ VILLALTA - 29 DE JUNIO DEL 2023   -> SE AGREGAN VALIDACIONES PARA QUE NO SE INGRESEN REGISTROS REPETIDOS EN LA TABLA TGFH_APA_Det_Prop_AP_CSal (RESOLUCION DE CASO 388443)
* ***/


SET NOCOUNT ON

/*** DECLARACION DE LAS VARIABLES PARA LA TABLA TGFH_APA_Propuesta_AP ***/

DECLARE @TC_Num_Accion AS VARCHAR(10),
        @TN_Tipo_Identificacion AS TINYINT,
        @TC_Identificacion_Pro AS VARCHAR(20),
        @TN_Tipo_Accion AS SMALLINT,
        @TN_Est_Accion AS TINYINT,
        @TF_Vigencia AS DATETIME,
        @TF_Fin_Vigencia AS DATETIME,
        @TN_Cod_Emisor AS TINYINT,
        @TC_Num_Acuerdo AS VARCHAR(20),
        @TN_Num_Accion_Anulada AS DECIMAL(10),
        @TC_Comentarios_Oficina AS VARCHAR(1000),
        @TC_Comentarios_CS AS VARCHAR(1000),
        @TC_Insertado_Por AS VARCHAR(200),
        @TF_Insercion AS DATETIME,
        @TC_Modificado_Por AS VARCHAR(200),
        @TF_Modificacion AS DATETIME,
        @TF_Fecha_Hoy AS DATETIME,
        @TN_Error_Tipo_Accion AS TINYINT,
        @TN_Num_Error AS INT,
        @TN_Tipo_Error AS TINYINT,
        @TC_Descripcion AS VARCHAR(1000)

/*** DECLARACION DE LAS VARIABLES QUE VIENEN DE LA TABLA TGFH_PIN_Proposicion ***/

DECLARE @TN_Num_Puesto AS INT, 
        @TN_Cod_Clase AS INT,
        @TN_Proposicion AS DECIMAL(10),
        @TN_Est_Proposicion_Procesada AS TINYINT,
        @TN_Est_Proposicion_Erronea AS TINYINT,
        @TC_Identificacion_Sust AS VARCHAR(20),
        @TC_Nombre_Pro AS VARCHAR(100),
        @TC_Nombre_Sust AS VARCHAR(100),
        @TN_Motivo AS TINYINT,
        @TC_Oficio AS VARCHAR(25),
        @TC_Nom_Oficina_Jud AS VARCHAR(100),
        @TC_Des_Clase AS VARCHAR(100),
        @TN_Consecutivo AS INT

/*** DECLARACION DE LAS VARIABLES PARA LA TABLA TGFH_APA_Det_Prop_AP_Fija ***/

DECLARE @TN_Cod_Ofi_Judicial AS INT,
		  @TN_Jornada_Lab_Ini AS TINYINT, 
		  @TN_Jornada_Lab_Fin AS TINYINT, 
		  @TN_Jornada_Lab AS TINYINT, 
		  @TN_Tipo_Incapacidad AS TINYINT, 
		  @TN_Forma_Pago AS TINYINT, 
		  @TN_Periodo_Vacaciones AS INT, 
		  @TN_Dias_Vacaciones AS TINYINT, 
		  @TN_Horas_Lab_Dia AS TINYINT, 
		  @TN_Tipo_Gas_Rep AS TINYINT, 
		  @TN_Ind_Dias_Naturales AS TINYINT, 
		  @TL_Ind_Mod_Car_Prof AS BIT, 
		  @TN_Esp_Medc AS TINYINT

/**DECLARACION PARA INSERTAR EN LA **/

DECLARE @TN_Cod_Ofi_Madre AS INT

/*** DECLARACION DE LAS VARIABLES PARA LA TABLA TGFH_APA_Det_Prop_AP_CSal ***/

DECLARE @TN_Cod_Componente_Sal_REFJ AS SMALLINT,
		@TN_Cod_Componente_Sal_ICS AS SMALLINT,
        @TN_Cod_Desg_Comp AS TINYINT,
        @TC_Val_Formula AS VARCHAR(100),
        @TN_Anualidades AS SMALLINT,
        @TN_Ptos_Car_Prof AS DECIMAL(5,2), 
        @TF_Anualidad AS DATETIME
        
/*** LUIS QUESADA - 24-04-2009***/        
/*** DECLARACIÓN DE LAS VARIABLES LOS COMPONENTES ICS -  TRACTOS 2, 3 Y 4 ***/
DECLARE @TN_Cod_Componente_Sal_ICS_2 AS SMALLINT
DECLARE @TN_Cod_Componente_Sal_ICS_3 AS SMALLINT
DECLARE @TN_Cod_Componente_Sal_ICS_4 AS SMALLINT
/*** FIN ***/        


/*** DECLARACION DE LAS VARIABLES PARA LOS DATOS QUE SE TRAEN DE TGFH_ESA_Est_Sal ***/

DECLARE @TC_Identificacion_Est AS VARCHAR(20),
        @TF_Vigencia_Est AS DATETIME, 
        @TF_Fin_Vigencia_Est AS DATETIME,
        @TN_Num_Puesto_Est AS INT,
        @TN_Cod_Clase_Est AS INT

/*** DECLARACION DE LAS VARIABLES PARA CALCULAR EL RANGO DE FECHAS SEGUN CADA ESTRUCTURA ***/

DECLARE @InicioVigencia AS DATETIME,
        @FinVigencia AS DATETIME  

/*** VARIABLES PARA PROCESO DE PRORROGAS********************************************************************************/
declare @TGFH_APA_Det_Prop_AP_CSal as table(
	[TN_Num_Accion] [decimal](10, 0) NOT NULL,
	[TN_Cod_Componente_Sal] [smallint] NOT NULL,
	[TN_Cod_Desg_Comp] [tinyint] NOT NULL,
	[TC_Val_Formula] [varchar](100) NULL,
	[TN_Anualidades] [smallint] NULL,
	[TN_Ptos_Car_Prof] [decimal](5, 2) NULL,
	[TF_Anualidad] [datetime] NULL, 
	[FILA] [int] identity(1, 1)
)
DECLARE @FILA_INICIO AS INT
DECLARE @FILA_FIN AS INT
DECLARE @ACCION_PRORROGA AS VARCHAR(25)
DECLARE @FECHA_INICIO_ACCION_PRORROGADA DATETIME
DECLARE @FECHA_FIN_ACCION_PRORROGADA DATETIME
DECLARE @COMENTARIO VARCHAR(MAX)
DECLARE @DEDICACION_EXCLUS INT
DECLARE @TIPO_IDEN INT =  NULL
DECLARE @IDEN	VARCHAR(50) = NULL
DECLARE @FECHA DATETIME = NULL

/****FIN VARIBALES DE PROCESO PRORROGAS***********************************************************************************/

/*** DECLARACION DE LAS VARIABLES PARA DETERMINAR QUE TIPO DE VOLCADO SE REALIZARÁ ***/
/*
DECLARE @TC_Fecha_Inicial AS DATETIME,
        @TC_Fecha_Final AS DATETIME 

SET @TC_Fecha_Inicial = '2007-06-11' 
SET @TC_Fecha_Final = '2007-06-14'
*/

/*** DECLARACION DE LA CONSTANTE PARA LA SELECCIÓN DINÁMICA DEL SERVIDOR 
*	 Y LA VARIABLE @SQL DONDE SE INGRESARA EL SQL A EJECUTAR EN EL SERVIDOR DONDE ESTE GFH***/

/*se cambia		LNK.GFH.dbo.
* por			GFHvirtual01sql2000.GFH.dbo.
* */
/*** LQM, 16 DE ABRIL DEL 2009 ***/
DECLARE @TC_Servidor_SIGA AS VARCHAR(200)
--DECLARE @TC_link AS VARCHAR(20)
DECLARE @TC_Data_Source as varchar(50)
DECLARE @TC_Base_Datos as varchar(20)

--SET @TC_link = ''
set @TC_Data_Source = @@SERVERNAME
set @TC_Base_Datos = 'GFH'

SET @TC_Servidor_SIGA = @TC_Base_Datos + '.dbo.'

DECLARE @SQL AS VARCHAR (MAX)
DECLARE @TN_Agno AS INT
DECLARE @NULL AS CHAR (4)

SET @NULL = 'NULL'
/*** LQM, 16 DE ABRIL DEL 2009 ***/

/******************************************************************************************************/
--Iniciamos el proceso asignando un nuevo código de volcado.
DECLARE @tn_volcado as int
Select @tn_volcado = max(tn_volcado) + 1 from tgfh_pin_volcado

insert into tgfh_pin_volcado
(tn_volcado, tn_tipo_volcado, tf_fecha_inicio, tc_cod_usuario, tf_vigencia, tf_fin_vigencia)
values (@tn_volcado, 5, getdate(), @TC_Cod_Usuario, @TC_Fecha_Inicial, @TC_Fecha_Final)

/******************************************************************************************************/

/*** DECLARACION DEL CURSOR DE PROPOSICIONES DEL PIN ***/
/*MODIFICADO POR CÉLIMO ELIZONDO INICIO */
IF @TC_Tipo_Volcado = 'PROPOSICIONES'
BEGIN
	DECLARE curProposiciones CURSOR FOR SELECT TGFH_PIN_Proposicion.TN_Proposicion,
											   TGFH_PIN_Proposicion.TC_Identificacion_Pro,
									  		   TGFH_PIN_Proposicion.TC_Nombre_Pro,
											   TGFH_PIN_Proposicion.TC_Identificacion_Sust,
											   TGFH_PIN_Proposicion.TC_Nombre_Sust,
											   TGFH_PIN_Proposicion.TN_Motivo,
											   TGFH_PIN_Proposicion.TF_Vigencia, 
											   TGFH_PIN_Proposicion.TF_Fin_Vigencia, 
											   TGFH_PIN_Proposicion.TC_Observacion, 
											   TGFH_PIN_Proposicion.TN_Cod_Ofi_Hija,
											   TGEN_PGA_Oficina_Judicial.TC_Nom_Oficina_Jud, 
											   TGFH_PIN_Proposicion.TN_Num_Puesto, 
											   TGFH_PIN_Proposicion.TN_Cod_Clase,
											   TGFH_PIN_Proposicion.TC_Des_Clase,
											   TGFH_PIN_Oficio.TC_Oficio,
											   TGFH_PIN_Proposicion.TN_Cod_Ofi_Madre
/***********************************************************************************************
LQM, 28/03/2017 
Tarea 42329:Volcados PIN para extranjeros
***********************************************************************************************/
											, tgfh_pin_proposicion.TN_TipoIdeProp
/**********************************************************************************************/
										FROM TGFH_PIN_Oficio 
										INNER JOIN TGFH_PIN_Proposicion ON TGFH_PIN_Oficio.TC_Oficio = TGFH_PIN_Proposicion.TC_Oficio AND TGFH_PIN_Oficio.TN_Cod_Ofi_Judicial = TGFH_PIN_Proposicion.TN_Cod_Ofi_Madre
										INNER JOIN TGEN_PGA_Oficina_Judicial ON TGFH_PIN_Proposicion.TN_Cod_Ofi_Hija = TGEN_PGA_Oficina_Judicial.TN_Cod_Ofi_Judicial
										WHERE (TGFH_PIN_Oficio.TN_Est_Oficio = 2) 
										AND (TGFH_PIN_Oficio.TF_Aprobacion BETWEEN CONVERT(DATETIME, @TC_Fecha_Inicial, 102) AND CONVERT(DATETIME, @TC_Fecha_Final, 102)) 

										AND (TGFH_PIN_Oficio.TN_Tipo = 1) 
										AND (TGFH_PIN_Proposicion.TN_Tipo_Reg = 1) 
										--and tn_Est_procesada = 99 --código 
										AND	(TGFH_PIN_Proposicion.TN_Est_Procesada = 1 OR TGFH_PIN_Proposicion.TN_Est_Procesada = 10 OR TGFH_PIN_Proposicion.TN_Est_Procesada = 4)
/*******************************************************************************************/
--										AND tn_proposicion in (1150249,1150297,1150298,1150299,1150305,1150311,1150312,1150257,1150264,1150275,1150282,1150410,1150418,1150430,1150431,1150423,1150100,1150138,1150135,1150151,1150159,1150160,1150188,1150197,1150147,1150158,1150161,1150165,1150180,1150209,1150205,1150230,1150488,1150505,1150506,1150517,1153769,1153239,1153255,1153276,1150938,1150939,1151115,1151092,1151108,1151161,1151475,1151481,1152014,1152038,1151963,1152143,1150281,1150316,1150331,1150338,1150359,1150363,1150365,1150346,1150364,1150382,1150398,1150405,1150424,1150428,1150432)
/*******************************************************************************************/

										--and TGFH_PIN_Oficio.TC_Oficio in ('PMR-331-2015',  'AGA-01-2016',         'AGA-02-2016',        'AGA-03-2016',        'AGA-04-2016',        'AGA-06-2016', 'AGA-07-2016')
										--and TGFH_PIN_Oficio.TC_Oficio = 'AGA-16-2016'

										ORDER BY TGFH_PIN_Proposicion.TN_Proposicion
	--SET @TC_Insertado_Por = 'INSERTADA POR EL PIN'										
	SET @TC_Insertado_Por = 'PIN00001'
END
ELSE
BEGIN
	IF @TC_Tipo_Volcado = 'TERNAELECTRONICA'
	BEGIN
		DECLARE curProposiciones CURSOR FOR SELECT TGFH_PIN_Proposicion.TN_Proposicion,
												   TGFH_PIN_Proposicion.TC_Identificacion_Pro,
									  			   TGFH_PIN_Proposicion.TC_Nombre_Pro,
												   TGFH_PIN_Proposicion.TC_Identificacion_Sust,
												   TGFH_PIN_Proposicion.TC_Nombre_Sust,
												   TGFH_PIN_Proposicion.TN_Motivo,
												   TGFH_PIN_Proposicion.TF_Vigencia, 
												   TGFH_PIN_Proposicion.TF_Fin_Vigencia, 
												   TGFH_PIN_Proposicion.TC_Observacion, 
												   TGFH_PIN_Proposicion.TN_Cod_Ofi_Hija,
												   TGEN_PGA_Oficina_Judicial.TC_Nom_Oficina_Jud, 
												   TGFH_PIN_Proposicion.TN_Num_Puesto, 
												   TGFH_PIN_Proposicion.TN_Cod_Clase,
												   TGFH_PIN_Proposicion.TC_Des_Clase,
												   TGFH_PIN_Oficio.TC_Oficio,
												   TGFH_PIN_Proposicion.TN_Cod_Ofi_Madre	
/***********************************************************************************************
LQM, 28/03/2017 
Tarea 42329:Volcados PIN para extranjeros
***********************************************************************************************/
											, tgfh_pin_proposicion.TN_TipoIdeProp
/**********************************************************************************************/												   											   
											FROM TGFH_PIN_Oficio 
											INNER JOIN TGFH_PIN_Proposicion ON TGFH_PIN_Oficio.TC_Oficio = TGFH_PIN_Proposicion.TC_Oficio AND TGFH_PIN_Oficio.TN_Cod_Ofi_Judicial = TGFH_PIN_Proposicion.TN_Cod_Ofi_Madre
											INNER JOIN TGEN_PGA_Oficina_Judicial ON TGFH_PIN_Proposicion.TN_Cod_Ofi_Hija = TGEN_PGA_Oficina_Judicial.TN_Cod_Ofi_Judicial
											WHERE (TGFH_PIN_Oficio.TN_Est_Oficio = 2) 
											--AND (CONVERT(DATETIME,CONVERT(VARCHAR(10),TGFH_PIN_Oficio.TF_Aprobacion,102)) BETWEEN CONVERT(DATETIME, @TC_Fecha_Inicial, 102) AND CONVERT(DATETIME, @TC_Fecha_Final, 102)) 
											AND (TGFH_PIN_Oficio.TN_Tipo = 3)--> Tipo Oficio 3 -> Terna Electrónica 
											AND (TGFH_PIN_Proposicion.TN_Tipo_Reg = 1) 
											AND	(TGFH_PIN_Proposicion.TN_Est_Procesada = 1 OR TGFH_PIN_Proposicion.TN_Est_Procesada = 10 OR TGFH_PIN_Proposicion.TN_Est_Procesada = 4)
											AND (TGFH_PIN_Oficio.TN_Cod_Ofi_Judicial = 3 OR dbo.TGFH_PIN_Oficio.TN_Cod_Ofi_Judicial = (SELECT TC_Primer_Valor FROM GFH.DBO.TGFH_PGA_Par_General WHERE TN_Cod_Parametro = 109))
											ORDER BY TGFH_PIN_Proposicion.TN_Proposicion		
		--SET @TC_Insertado_Por = 'INSERTADA POR EL SACJ'
		SET @TC_Insertado_Por = 'SACJ0001'
	END
END									

/*** DECLARACION DE VALORES QUE SON CONSTANTES ***/

SET @TN_Tipo_Identificacion = 1
SET @TN_Est_Accion = 1
SET @TN_Cod_Emisor = NULL
SET @TC_Num_Acuerdo = NULL
SET @TN_Num_Accion_Anulada = NULL
SET @TC_Comentarios_CS = NULL

SET @TF_Insercion = GETDATE()
SET @TC_Modificado_Por = NULL
SET @TF_Modificacion = NULL
SET @TN_Est_Proposicion_Procesada = 2
SET @TN_Est_Proposicion_Erronea = 3
SET @TN_Jornada_Lab_Ini = 1 
SET @TN_Jornada_Lab_Fin = 1
SET @TN_Jornada_Lab = 1
SET @TN_Tipo_Incapacidad = NULL
SET @TN_Forma_Pago = 1
SET @TN_Periodo_Vacaciones = NULL
SET @TN_Dias_Vacaciones = NULL
SET @TN_Horas_Lab_Dia = 0
SET @TN_Tipo_Gas_Rep = NULL
SET @TN_Ind_Dias_Naturales = NULL
SET @TL_Ind_Mod_Car_Prof = NULL
SET @TN_Esp_Medc = NULL
SET @TN_Cod_Componente_Sal_REFJ = 2 
SET @TN_Cod_Componente_Sal_ICS = 36
SET @TC_Val_Formula = NULL
SET @TN_Anualidades = NULL
SET @TN_Ptos_Car_Prof = NULL
SET @TF_Anualidad = NULL
SET @TF_Fecha_Hoy = GETDATE()
SET @TN_Error_Tipo_Accion = 80

/*** LUIS QUESADA - 24-04-2009***/        
/*** DECLARACIÓN DE LAS VARIABLES LOS COMPONENTES ICS -  TRACTOS 2, 3 Y 4 ***/
SET @TN_Cod_Componente_Sal_ICS_2 = 39
SET @TN_Cod_Componente_Sal_ICS_3 = 40
SET @TN_Cod_Componente_Sal_ICS_4 = 41
/*** FIN ***/        

/*** OJO, HAY QUE DEFINIR BIEN ESTAS VARIABLES Y UNA VEZ HECHO ESTO, QUITARLAS DE AQUI ***/

SET @TN_Tipo_Error = 1
SET @TC_Descripcion = 'ERROR POR DEFINIR (VOLCADO DE PROPOSICIONES)'

/*** ABRE EL CURSOR PROPOSICIONES ***/

OPEN curProposiciones

/*** TOMA LOS VALORES DE LA PRIMERA FILA DEL LISTADO Y LOS ASIGNA A LAS VARIABLES  ***/

FETCH NEXT FROM curProposiciones INTO @TN_Proposicion,
                                      @TC_Identificacion_Pro,
									  @TC_Nombre_Pro,
									  @TC_Identificacion_Sust,
									  @TC_Nombre_Sust,
									  @TN_Motivo,
								      @TF_Vigencia,
								      @TF_Fin_Vigencia,
								      @TC_Comentarios_Oficina,
								      @TN_Cod_Ofi_Judicial,
									  @TC_Nom_Oficina_Jud,
								      @TN_Num_Puesto,
							 	      @TN_Cod_Clase,	
									  @TC_Des_Clase,
									  @TC_Oficio,
									  @TN_Cod_Ofi_Madre
/***********************************************************************************************
LQM, 28/03/2017 
Tarea 42329:Volcados PIN para extranjeros
***********************************************************************************************/
										, @tn_tipo_identificacion
/***********************************************************************************************/
PRINT '<table border = 0 align = "center"><tr><td align = "center"><h1>REPORTE DEL VOLCADO DE PROPOSICIONES DEL: ' + CONVERT(VARCHAR(20),@TC_Fecha_Inicial,103) + ' AL '+ CONVERT(VARCHAR(20),@TC_Fecha_Final,103)  + ' EMITIDO EL ' + CONVERT(VARCHAR(20),GETDATE(),103)  +   ' A LAS: ' + CONVERT(VARCHAR(20),GETDATE(),108) +  '</h1></td></tr></table>'

PRINT '<table border = 1><tr><td>PROPOSICION</td><td>OFICINA</td><td>TIPO ACCION</td><td>CEDULA PRO</td><td>NOMBRE PRO</td><td>PERIODO</td><td>CLASE PUESTO</td><td>NUM PUESTO</td><td>COMENTARIO</td><td>COMENTARIO OFICINA</td><td>ACCION</td></tr>'

/*** CICLO DEL CURSOR PROPOSICIONES ***/

WHILE @@FETCH_STATUS = 0 BEGIN    
	/*	
	PRINT ''
	PRINT '************************** PROPOSICION ' + CONVERT(VARCHAR(20), @TN_Proposicion) + ' ********************************'
	PRINT ''
	
	PRINT  'PROPOSICIÓN ' + CONVERT(VARCHAR, @TN_Proposicion) 
		  + ' CEDULA: ' + @TC_Identificacion_Pro
        + ' DEL ' + CONVERT(VARCHAR, @TF_Vigencia,103) 
	     + ' AL ' + CONVERT(VARCHAR, @TF_Fin_Vigencia,103) 
	     + ' CLASE: ' + CONVERT(VARCHAR, @TN_Cod_Clase) 
	     + ' PUESTO: ' + CONVERT(VARCHAR, @TN_Num_Puesto)        
	PRINT ''
	*/
	
	--SET @TC_Comentarios_Oficina =  ' OFICIO: ' + @TC_Oficio + ' - ' + ISNULL(@TC_Comentarios_Oficina, '') 

	
	/*** DECLARACION DEL CURSOR QUE CONTENDRÁ LAS POSIBLES ESTRUCTURAS PARA CADA NOMBRAMIENTO ***/
	IF @TF_Fin_Vigencia <> CONVERT(DATETIME, '1900-01-01 00:00:00', 102)
	BEGIN
		DECLARE curEstructura CURSOR FOR SELECT TC_Identificacion,
									    		TF_Vigencia,
												TF_Fin_Vigencia,
												TN_Num_Puesto,
												TN_Cod_Clase
										 FROM TGFH_ESA_Est_Sal_Emp
										 WHERE TF_Vigencia <= @TF_Fin_Vigencia 
										 AND (TF_Fin_Vigencia >= @TF_Vigencia OR TF_Fin_Vigencia IS NULL OR TF_Fin_Vigencia = CONVERT(DATETIME, '1900-01-01 00:00:00', 102)) 
										 AND TC_Identificacion = @TC_Identificacion_Pro
										 ORDER BY TF_Vigencia
	END
	ELSE
	BEGIN
	
		DECLARE curEstructura CURSOR FOR SELECT TC_Identificacion,
									    		TF_Vigencia,
												TF_Fin_Vigencia,
												TN_Num_Puesto,
												TN_Cod_Clase
										 FROM TGFH_ESA_Est_Sal_Emp
										 WHERE TF_Vigencia <= @TF_Vigencia 
										 AND (TF_Fin_Vigencia >= @TF_Vigencia OR TF_Fin_Vigencia IS NULL OR TF_Fin_Vigencia = CONVERT(DATETIME, '1900-01-01 00:00:00', 102)) 
										 AND TC_Identificacion = @TC_Identificacion_Pro
										 ORDER BY TF_Vigencia		
	END
	
	/*** ABRE EL CURSOR ESTRUCTURA ***/

	OPEN curEstructura
	
	/*** TOMA LOS VALORES DE LA PRIMERA FILA DEL LISTADO Y LOS ASIGNA A LAS VARIABLES  ***/

	FETCH NEXT FROM curEstructura INTO @TC_Identificacion_Est,
									   @TF_Vigencia_Est,
									   @TF_Fin_Vigencia_Est,
									   @TN_Num_Puesto_Est,
									   @TN_Cod_Clase_Est

	/*** REVISA SI TIENE ESTRUCTURA ***/

	IF @@FETCH_STATUS = 0 BEGIN	
		/*** CICLO DEL CURSOR ESTRUCTURA ***/
		WHILE @@FETCH_STATUS = 0 BEGIN
				/*
				PRINT ' -----> ESTRUCTURA DEL ' +
						CONVERT(VARCHAR,@TF_Vigencia_Est,103) + ' AL ' + 
						CONVERT(VARCHAR,@TF_Fin_Vigencia_Est,103) + ' CLASE: ' + 
						CONVERT(VARCHAR,@TN_Cod_Clase_Est) + ' PUESTO: ' + 
						CONVERT(VARCHAR,@TN_Num_Puesto_Est)
				PRINT ''
				*/
				
				IF @TF_Vigencia_Est <= @TF_Vigencia AND (@TF_Fin_Vigencia_Est >= @TF_Vigencia OR @TF_Fin_Vigencia_Est = '1900-01-01') 
					SET @InicioVigencia = @TF_Vigencia			
				ELSE IF @TF_Vigencia_Est >= @TF_Vigencia AND (@TF_Fin_Vigencia_Est >= @TF_Vigencia OR @TF_Fin_Vigencia_Est = '1900-01-01')
					SET @InicioVigencia = @TF_Vigencia_Est

				IF @TF_Fin_Vigencia = '1900-01-01'
					
					SET @FinVigencia = @TF_Fin_Vigencia
					 			
				ELSE IF @TF_Vigencia_Est <= @TF_Fin_Vigencia AND (@TF_Fin_Vigencia_Est >= @TF_Fin_Vigencia OR @TF_Fin_Vigencia_Est = '1900-01-01') 
				
					SET @FinVigencia = @TF_Fin_Vigencia
			/**SSALGUERAZ - 14-03-2018 - Tarea 77604 Caso 36041*/
			    ELSE IF @TF_Fin_Vigencia_Est = @TF_Vigencia AND @TF_Fin_Vigencia > @TF_Fin_Vigencia_Est
					 SET @FinVigencia = @TF_Fin_Vigencia
			/**SSALGUERAZ - 14-03-2018 - Tarea 77604 Caso 36041*/
			
				ELSE IF @TF_Vigencia_Est <= @TF_Fin_Vigencia AND (@TF_Fin_Vigencia_Est <= @TF_Fin_Vigencia OR @TF_Fin_Vigencia_Est = '1900-01-01') 
			
					SET @FinVigencia = @TF_Fin_Vigencia_Est				

				/*** OBTIENE EL SIGUIENTE NUMERO DE CONSECUTIVO  ***/


/*********************************************************************************************************************
*  Código documentado por Luis Quesada -> 16/04/2009

* 
	
					SELECT @TN_Consecutivo = TN_Consecutivo + 1
					FROM  GFHvirtual01sql2000.GFH.dbo.TGFH_APA_Consecutivo_AP --TGFH_APA_Consecutivo_AP --
	/*Original				WHERE TN_Anno_Consecutivo = YEAR(@TF_Vigencia)                                                                          */
	/*Modificado 21-01-2008 12:50*/		WHERE TN_Anno_Consecutivo = YEAR(@InicioVigencia)
*/
				SET @TN_Agno = YEAR(@InicioVigencia)
				
				
				--************CAMBIAR A LA CONEXION DE PRODUCCIÓN******
				EXEC sp_ConsecutivoGFH @TN_Agno, @TC_Servidor_SIGA, @TN_Consecutivo OUTPUT				
/*********************************************************************************************************************/
				/*** OBTIENE EL NUMERO DE ACCION A INSERTAR  ***/
				SELECT @TC_Num_Accion = CASE 
				                        WHEN @TN_Consecutivo < 10 THEN '00000' + CONVERT(Char(1), @TN_Consecutivo) 
				              	     	WHEN @TN_Consecutivo < 100 THEN '0000' + CONVERT(Char(2), @TN_Consecutivo)
						             	WHEN @TN_Consecutivo < 1000 THEN '000' + CONVERT(Char(3), @TN_Consecutivo)
				  		 	            WHEN @TN_Consecutivo < 10000 THEN '00' + CONVERT(Char(4), @TN_Consecutivo)
							            WHEN @TN_Consecutivo < 100000 THEN '0' + CONVERT(Char(5), @TN_Consecutivo)
							            WHEN @TN_Consecutivo < 1000000 THEN CONVERT(Char(6), @TN_Consecutivo) 
					                    END

/***LQM 2016/08/26  para que se analice el motivo de 1/2 tiempo****/
			   if @TN_Motivo = 32 begin
					SET @TN_Tipo_Accion = 28 --por defecto si van a nombrar medio tiempo es por ser nombramiento interino
			   end
			   else begin
/**********************************************************************/
					SET @TN_Tipo_Accion = dbo.fVerificaTipoAccion(@TC_Identificacion_Pro, 
															 @InicioVigencia, 
															 @FinVigencia,
															 @TN_Cod_Clase,
			                                                 @TN_Num_Puesto)				

/*******************SSALGUERAZ - 14-03-2018***Tarea 77604 Caso 36041******************************************************************** */
		if @TN_Tipo_Accion = 80 
			and ( 
					--si el nombramiento inicia sábado y es de mas de dos días
					(DATEPART(dw, @InicioVigencia) = 7 and DATEDIFF(dd, @InicioVigencia, @FinVigencia) >= 2)
					or
					--si el nombramiento inicia domingo
					(DATEPART(dw, @InicioVigencia) = 1 and DATEDIFF(dd, @InicioVigencia, @FinVigencia) >= 1)
					
				)
		begin
			--se llama recursivamente a la función pero con vigencia de dos días adelante, si el inicio es sábado.
			--Lo anterior para evitar cuando el nombramiento anterior iva hasta un viernes que fue extendido en GFH al domingo
			--o que llegó al sábado y fue extendido al domingo por cuanto corresponde todo el pago del fin de semana.
			set @TN_Tipo_Accion = dbo.fVerificaTipoAccion(@TC_Identificacion_Pro, 
															 dateadd(dd, case when DATEPART(dw, @InicioVigencia) = 7 then 2 else 1 end, @InicioVigencia), 
															 @FinVigencia,
															 @TN_Cod_Clase,
			                                                 @TN_Num_Puesto)	

					IF @TN_Tipo_Accion <> 80 
					BEGIN
						SET @InicioVigencia = dateadd(dd, case when DATEPART(dw, @InicioVigencia) = 7 then 2 else 1 end, @InicioVigencia)
					END
		end		
/*********************SSALGUERAZ - 14-03-2018***Tarea 77604 Caso 36041 *****************************************************************/	

				end

				/*** VERIFICA SI EL TIPO DE PROPOSICION ES VÁLIDO O ES ERRONEO  ***/			
				IF @TN_Tipo_Accion <> @TN_Error_Tipo_Accion BEGIN
			
					/*** VERIFICA SI ES UNA PLAZA VACANTE  ***/				   

					/********************************************************************************************************/
					--LQM 26/01/2016
					select @TC_Comentarios_CS = tc_des_motivo from TGFH_PIN_Motivo_Proposicion where tn_cod_motivo = @TN_Motivo
					set @TC_Comentarios_CS = isnull(@TC_Comentarios_CS, 'Coordinar con TI el tipo de acción')

					IF @TN_Motivo = 1 or @TN_Motivo = 32
						SET @TC_Comentarios_CS = 'PLAZA VACANTE' + ' OFICIO: ' + @TC_Oficio					
					 ELSE				
					 --SET @TC_Comentarios_CS = 'SUSTITUYE A-> CEDULA: ' + @TC_Identificacion_Sust + ' NOMBRE :' + @TC_Nombre_Sust + ' MOTIVO: ' + CASE @TN_Motivo WHEN 1 THEN 'PLAZA VACANTE' WHEN 2 THEN 'VACACIONES' WHEN 3 THEN 'INCAPACIDAD'  WHEN 4 THEN 'PERMISO CON GOCE DE SALARIO'  WHEN 5 THEN 'PERMISO SIN GOCE DE SALARIO' WHEN 6 THEN 'SUSPENSION' WHEN 7 THEN 'ASCENSO A OTRO CARGO' WHEN 8 THEN 'Plaza Extraordinaria' WHEN 9 THEN 'Permiso con sueldo total por beca' ELSE 'PERMISO CON' END + ' OFICIO: ' + @TC_Oficio 
						SET @TC_Comentarios_CS = 'SUSTITUYE A-> CEDULA: ' + @TC_Identificacion_Sust + ' NOMBRE :' + @TC_Nombre_Sust + ' MOTIVO: ' + @TC_Comentarios_CS + ' OFICIO: ' + @TC_Oficio 
						
					set @TC_Comentarios_CS = isnull(@TC_Comentarios_CS, 'Coordinar con TI el tipo de acción')
					/********************************************************************************************************/

					--PRINT ' -----> INSERTAR EN ACCIONES: ' + 'ACCIÓN: ' + CONVERT(VARCHAR,YEAR(@TF_Vigencia)) + CONVERT(VARCHAR,@TC_Num_Accion) + ' TIPO: ' + CONVERT(VARCHAR, @TN_Tipo_Accion) + ' VIGENCIA: ' + CONVERT(VARCHAR,@InicioVigencia, 103) + ' FIN VIGENCIA: ' + CONVERT(VARCHAR,@FinVigencia, 103)

					PRINT '<tr><td>' + CONVERT(VARCHAR(20), @TN_Proposicion)  + '</td><td>' +  @TC_Nom_Oficina_Jud  + '</td><td>' +  				         
				         CASE @TN_Tipo_Accion WHEN 26 THEN 'NOMBRAMIENTO PROPIEDAD' WHEN 28 THEN 'NOMBRAMIENTO INTERINO' WHEN 31 THEN 'ASCENSO PROPIEDAD' WHEN 32 THEN 'ASCENSO INTERINO' WHEN 34 THEN 'DESCENSO PROPIEDAD' WHEN 35 THEN 'DESCENSO INTERINO' WHEN 40 THEN 'TRASLADO INTERINO' WHEN 41 THEN 'TRASLADO PROPIEDAD' END + '</td><td>' +
				         @TC_Identificacion_Pro + '</td><td>' + @TC_Nombre_Pro + '</td><td>' + 
					      CONVERT(VARCHAR(20), @TF_Vigencia, 103) + ' - ' + CONVERT(VARCHAR(20), @TF_Fin_Vigencia, 103) + '</td><td>' + 
				         @TC_Des_Clase + '</td><td>' + CONVERT(VARCHAR(20), @TN_Num_Puesto) + '</td><td>' + @TC_Comentarios_CS + '</td><td>' + @TC_Comentarios_Oficina + '</td><td>' +
				         CONVERT(VARCHAR,YEAR(@TF_Vigencia)) + CONVERT(VARCHAR,@TC_Num_Accion) + '</tr>' 
					
					/*** INSERTA LOS VALORES EN LA TABLA TGFH_APA_Propuesta_AP  ***/
					/*TGFH_APA_Propuesta_AP_Volcado */ 
					
					--************CAMBIAR A LA CONEXION DE PRODUCCIÓN******
				   SET @SQL = ' INSERT INTO ' + @TC_Servidor_SIGA + 'TGFH_APA_Propuesta_AP ' +
								'(TN_Num_Accion, TN_Tipo_Identificacion, TC_Identificacion, TN_Tipo_Accion, '+
								'TN_Est_Accion, TF_Vigencia, TF_Fin_Vigencia, TN_Cod_Emisor, TC_Num_Acuerdo, '+
								'TN_Num_Accion_Anulada, TC_Comentarios_Oficina, TC_Comentarios_CS, TC_Insertado_Por, '+
								'TF_Insercion, TC_Modificado_Por, TF_Modificacion) '+
								'VALUES(' + CONVERT(VARCHAR,YEAR(@InicioVigencia)) + CONVERT(VARCHAR,@TC_Num_Accion)+ ',' +
								ISNULL(CONVERT(VARCHAR,@TN_Tipo_Identificacion), @NULL)+ ', ''' + 
								ISNULL(@TC_Identificacion_Pro, @NULL)+ ''' ,' + 
								ISNULL(CONVERT(VARCHAR,@TN_Tipo_Accion), @NULL)+ ',' + 
								ISNULL(CONVERT(VARCHAR,@TN_Est_Accion), @NULL)+ ', ' + 							
								ISNULL(' ''' + convert(varchar,@InicioVigencia,111) + '  ' + convert(varchar,@InicioVigencia,108) + ''' ', @NULL) + ',' +
								ISNULL(' ''' + convert(varchar,@FinVigencia,111) + '  ' + convert(varchar,@FinVigencia,108) + ''' ', @NULL) + ',' +
								ISNULL(CONVERT(VARCHAR,@TN_Cod_Emisor), @NULL)+ ', ''' +
								ISNULL(@TC_Num_Acuerdo, @NULL)+ ''' ,' + 
								ISNULL(CONVERT(VARCHAR,@TN_Num_Accion_Anulada), @NULL)+ ', ''' + 
								ISNULL(@TC_Comentarios_Oficina, @NULL)+ ''' , ''' + 
								ISNULL(@TC_Comentarios_CS, @NULL)+ ''' , ''' + 
								ISNULL(@TC_Insertado_Por, @NULL)+ ''' ,' +
								ISNULL(' ''' + convert(varchar,@TF_Insercion,111) + '  ' + convert(varchar,@TF_Insercion,108) + ''' ', @NULL) + ', ''' +
								ISNULL(@TC_Modificado_Por, @NULL)+ ''' ,' +	
								ISNULL(' ''' + convert(varchar,@TF_Modificacion,111) + '  ' + convert(varchar,@TF_Modificacion,108) + ''' ', @NULL)  + ')'
								
					EXEC(@SQL)
			
					IF @@ERROR = 0 BEGIN 
				
					   /*** ACTUALIZA LA TABLA DE CONSECUTIVOS AP CON EL NUEVO NUMERO  ***/		   					   
					   
					   --************CAMBIAR A LA CONEXION DE PRODUCCIÓN******
					   SET @SQL  = 'UPDATE ' + @TC_Servidor_SIGA + 'TGFH_APA_Consecutivo_AP ' +
								   'SET TN_Consecutivo = ' + @TC_Num_Accion + 
								   ' WHERE TN_Anno_Consecutivo = ' + CONVERT(VARCHAR,YEAR(@InicioVigencia))
					   EXEC(@SQL)
					
					   /*** BUSCA EN LA TABLA DE PUESTOS SI EL PUESTO ES DE 4 O DE 8 HORAS  ***/
					
				/***LQM 2016/08/26  para que se analice el motivo de 1/2 tiempo****/
					   --SELECT @TN_Horas_Lab_Dia = TN_Horas_Lab_Dia
   						/**************************************************************************/
						--LQM 2017/06/01
						if @TN_Motivo = 32 begin
							set @TN_Horas_Lab_Dia = 4
						end
						else begin
						/**************************************************************************/
							set @TN_Horas_Lab_Dia = 8
						   SELECT @TN_Horas_Lab_Dia = TN_Horas_Lab_Dia
						   FROM TGFH_PGA_Puesto
						   WHERE TN_Num_Puesto = @TN_Num_Puesto
					   end 

					   SELECT @TN_Jornada_Lab_Ini = CASE WHEN @TN_Horas_Lab_Dia = 4 THEN dbo.fVerificaJornadaMedioTiempo(@TC_Identificacion_Pro,  @TF_Vigencia, @TF_Fin_Vigencia) ELSE 1 END
					   SET @TN_Jornada_Lab_Fin = @TN_Jornada_Lab_Ini
					   SET @TN_Jornada_Lab = @TN_Jornada_Lab_Ini
					   
/**********************************************************************/

					   /*** INSERTA LOS VALORES EN LA TABLA TGFH_APA_Det_Prop_AP_Fija  ***/
					   --************CAMBIAR A LA CONEXION DE PRODUCCIÓN******
					   SET @SQL  = 'INSERT INTO ' + @TC_Servidor_SIGA + 'TGFH_APA_Det_Prop_AP_Fija /*TGFH_APA_Det_Prop_AP_Fija_Volcado */ ' +
					         '(TN_Num_Accion, '+
						      ' TN_Cod_Ofi_Judicial, '+
					 	  		'TN_Jornada_Lab_Ini, '+
							    'TN_Jornada_Lab_Fin, '+
							    'TN_Jornada_Lab, '+
							    'TN_Tipo_Incapacidad, '+
							    'TN_Num_Puesto, '+
							    'TN_Cod_Clase, '+
							    'TN_Forma_Pago, '+
							    'TN_Periodo_Vacaciones, '+
							    'TN_Dias_Vacaciones, '+
							    'TN_Horas_Lab_Dia, '+
							    'TN_Tipo_Gas_Rep, '+
							    'TN_Ind_Dias_Naturales, '+
							    'TL_Ind_Mod_Car_Prof, '+
							    'TN_Esp_Medc) '+
					   'VALUES( ' + CONVERT(VARCHAR,YEAR(@InicioVigencia)) + CONVERT(VARCHAR,@TC_Num_Accion)+', '+
							    ISNULL(CONVERT(VARCHAR,@TN_Cod_Ofi_Judicial), @NULL)+', '+
							    ISNULL(CONVERT(VARCHAR,@TN_Jornada_Lab_Ini), @NULL)+', '+ 
							    ISNULL(CONVERT(VARCHAR,@TN_Jornada_Lab_Fin), @NULL)+', '+
							    ISNULL(CONVERT(VARCHAR,@TN_Jornada_Lab), @NULL)+', '+
							    ISNULL(CONVERT(VARCHAR,@TN_Tipo_Incapacidad), @NULL)+', '+ 
							    ISNULL(CONVERT(VARCHAR,@TN_Num_Puesto), @NULL)+', '+
							    ISNULL(CONVERT(VARCHAR,@TN_Cod_Clase), @NULL)+', '+
							    ISNULL(CONVERT(VARCHAR,@TN_Forma_Pago), @NULL)+', '+ 
							    ISNULL(CONVERT(VARCHAR,@TN_Periodo_Vacaciones), @NULL)+', '+
							    ISNULL(CONVERT(VARCHAR,@TN_Dias_Vacaciones), @NULL)+', '+
							    ISNULL(CONVERT(VARCHAR,@TN_Horas_Lab_Dia), @NULL)+', '+
							    ISNULL(CONVERT(VARCHAR,@TN_Tipo_Gas_Rep), @NULL)+', '+
							    ISNULL(CONVERT(VARCHAR,@TN_Ind_Dias_Naturales), @NULL)+', '+
							    ISNULL(CONVERT(VARCHAR,@TL_Ind_Mod_Car_Prof), @NULL)+', '+
							    ISNULL(CONVERT(VARCHAR,@TN_Esp_Medc), @NULL)+ ')'
						EXEC(@SQL)
						
					   /*** INSERTA LOS VALORES EN LA TABLA TGFH_APA_Det_Prop_AP_CSal DEL COMPONENTE REFJ ***/
/*SSALGUERAZ/INICIO --**********************- ESTA SECCION ES PARA MANEJAR LAS PRORROGAS DE NOMBRAMIENTO***************************/
			 
						/************************************************************************************************************************/
						/*** INSERTA LOS VALORES EN LA TABLA TGFH_APA_Det_Prop_AP_CSal cuando es una continuidad del nombramiento ***/
						/*** LQM, 03/06/2019 ***/

						-- PRIMER SELECT
						DELETE FROM @TGFH_APA_Det_Prop_AP_CSal
						IF EXISTS(SELECT TOP 1 1 FROM TGfh_esa_est_sal_emp E
										WHERE   TN_Tipo_Identificacion = ISNULL(CONVERT(VARCHAR,@TN_Tipo_Identificacion), @NULL)
											and TC_Identificacion = ISNULL(@TC_Identificacion_Pro, @NULL)
											and TN_Cod_Clase = ISNULL(CONVERT(VARCHAR,@TN_Cod_Clase), @NULL)
											and TN_Num_Puesto = ISNULL(CONVERT(VARCHAR,@TN_Num_Puesto), @NULL)
											and  CASE 
											       WHEN ISNULL(E.TF_Fin_Vigencia, '1900/01/01') = '1900/01/01' 
												     THEN '2999/12/31' 
												   ELSE E.TF_Fin_Vigencia END = DATEADD(dd, -1, @InicioVigencia) --PREGUNTO SI ES EL ULTIMO DIA
											and ISNULL(CONVERT(VARCHAR,@TN_Cod_Ofi_Judicial), @NULL) = (SELECT TOP 1 TN_Cod_Ofi_Judicial FROM TGfh_pga_puesto_oficina PO WHERE PO.TN_Num_Puesto = E.TN_Num_Puesto AND E.TF_Vigencia BETWEEN PO.TF_Vigencia AND CASE WHEN ISNULL(PO.TF_Fin_Vigencia, '1900/01/01') = '1900/01/01' THEN '2999/12/31' ELSE PO.TF_Fin_Vigencia END)
									)
						BEGIN
						--GUARDO LA ACCION A LA QUE SE LE HACE LA PRORROGA 
						    SET @ACCION_PRORROGA = (SELECT TN_Num_Accion FROM GFH.DBO.TGfh_esa_est_sal_emp E
										WHERE   TN_Tipo_Identificacion = ISNULL(CONVERT(VARCHAR,1), NULL)
											and TC_Identificacion = ISNULL(@TC_Identificacion_Pro, NULL)
											and TN_Cod_Clase = ISNULL(CONVERT(VARCHAR,@TN_Cod_Clase), NULL)
											and TN_Num_Puesto = ISNULL(CONVERT(VARCHAR,@TN_Num_Puesto), @NULL)
											and  CASE 
											       WHEN ISNULL(E.TF_Fin_Vigencia, '1900/01/01') = '1900/01/01' 
												     THEN '2999/12/31' 
												   ELSE E.TF_Fin_Vigencia END = DATEADD(dd, -1, @InicioVigencia) --PREGUNTO SI ES EL ULTIMO DIA
											and ISNULL(CONVERT(VARCHAR,@TN_Cod_Ofi_Judicial), null) = (SELECT TOP 1 TN_Cod_Ofi_Judicial FROM GFH.DBO.TGfh_pga_puesto_oficina PO 
																										WHERE PO.TN_Num_Puesto = E.TN_Num_Puesto AND E.TF_Vigencia BETWEEN PO.TF_Vigencia
																										AND CASE WHEN ISNULL(PO.TF_Fin_Vigencia, '1900/01/01') = '1900/01/01' 
																										THEN '2999/12/31' ELSE PO.TF_Fin_Vigencia END))
			
				------TOMO VIGENCIAS DE LA ACCION QUE SE ESTA PRORROGANDO
						SET @FECHA_INICIO_ACCION_PRORROGADA = (SELECT TF_VIGENCIA FROM GFH.DBO.TGfh_esa_est_sal_emp E WHERE E.TN_Num_Accion = @ACCION_PRORROGA
																			AND  CASE 
																										WHEN ISNULL(E.TF_Fin_Vigencia, '1900/01/01') = '1900/01/01' 
																											THEN '2999/12/31' 
																										ELSE E.TF_Fin_Vigencia END = DATEADD(dd, -1, @InicioVigencia) --PREGUNTO SI ES EL ULTIMO DIA
																								and ISNULL(CONVERT(VARCHAR,@TN_Cod_Ofi_Judicial), null) = (SELECT TOP 1 TN_Cod_Ofi_Judicial FROM GFH.DBO.TGfh_pga_puesto_oficina PO 
																																							WHERE PO.TN_Num_Puesto = E.TN_Num_Puesto AND E.TF_Vigencia BETWEEN PO.TF_Vigencia
																																							AND CASE WHEN ISNULL(PO.TF_Fin_Vigencia, '1900/01/01') = '1900/01/01' 
																																							THEN '2999/12/31' ELSE PO.TF_Fin_Vigencia END))
						SET @FECHA_FIN_ACCION_PRORROGADA = (SELECT TF_FIN_VIGENCIA FROM GFH.DBO.TGfh_esa_est_sal_emp E WHERE E.TN_Num_Accion = @ACCION_PRORROGA
																			AND  CASE 
																																							WHEN ISNULL(E.TF_Fin_Vigencia, '1900/01/01') = '1900/01/01' 
																																								THEN '2999/12/31' 
																																							ELSE E.TF_Fin_Vigencia END = DATEADD(dd, -1, @InicioVigencia) --PREGUNTO SI ES EL ULTIMO DIA
																																					and ISNULL(CONVERT(VARCHAR,@TN_Cod_Ofi_Judicial), null) = (SELECT TOP 1 TN_Cod_Ofi_Judicial FROM GFH.DBO.TGfh_pga_puesto_oficina PO 
																																																				WHERE PO.TN_Num_Puesto = E.TN_Num_Puesto AND E.TF_Vigencia BETWEEN PO.TF_Vigencia
																																																				AND CASE WHEN ISNULL(PO.TF_Fin_Vigencia, '1900/01/01') = '1900/01/01' 
																																																				THEN '2999/12/31' ELSE PO.TF_Fin_Vigencia END))


						SET @COMENTARIO = (SELECT TC_Comentarios_CS FROM GFH.DBO.TGfh_apa_propuesta_ap WHERE TN_Num_Accion = CONVERT(VARCHAR,YEAR(@InicioVigencia)) + CONVERT(VARCHAR,@TC_Num_Accion) )
			            SET @COMENTARIO =  @COMENTARIO + ' - Prórroga de la acción número = '

				------ACTUALIZO LA PROPUESTA Y LA PONGO APROBADA
			              SET @SQL ='UPDATE TGfh_apa_propuesta_ap' 
						   + ' SET TN_Est_Accion = 2'
						   +', TC_Comentarios_CS =' + CHAR(39) + CAST(ISNULL(@COMENTARIO,'') AS VARCHAR(MAX)) + CAST(@ACCION_PRORROGA AS VARCHAR) + CHAR(39) 
						   + ' WHERE TN_Num_Accion =' + CONVERT(VARCHAR,YEAR(@InicioVigencia)) + CONVERT(VARCHAR,@TC_Num_Accion) 

						  EXEC(@SQL)   
				  -------------------TRAIGO LOS  COMPONENTES	QUE TRAIA LA ACCION QUE SE VA A PRORROGAR------
							INSERT INTO @TGFH_APA_Det_Prop_AP_CSal
								([TN_Num_Accion]			
								,[TN_Cod_Componente_Sal]		
								,[TN_Cod_Desg_Comp]			
								,[TC_Val_Formula]
								,[TN_Anualidades]			
								,[TN_Ptos_Car_Prof]
								,[TF_Anualidad])
							SELECT 0 TN_Num_Accion, A.[TN_Cod_Componente_Sal], [TN_Cod_Desg_Comp],  null TC_Val_Formula, 
									CASE WHEN A.tn_cod_componente_sal = 18 and tn_cod_desg_comp = 1 
										THEN tn_anualidades_cap 
									ELSE tn_anualidades 
									end	[TN_Anualidades]
									,TN_Puntos_Car_Prof
									,null [TF_Anualidad]
									FROM GFH.DBO.TGFH_ESA_CSal_Emp A
									INNER JOIN GFH.DBO.TGFH_ESA_Componente_Sal  b on a.TN_Cod_Componente_Sal = b.TN_Cod_Componente_Sal
									WHERE a.TC_Identificacion = ISNULL(@TC_Identificacion_Pro, @NULL)
									AND A.TN_Tipo_Identificacion = ISNULL(CONVERT(VARCHAR,@TN_Tipo_Identificacion), @NULL)
									AND TF_Vigencia <= @FECHA_FIN_ACCION_PRORROGADA and (TF_Fin_Vigencia >= @FECHA_INICIO_ACCION_PRORROGADA OR isnull(TF_Fin_Vigencia,'19000101') = '19000101') 
									ORDER BY TF_Vigencia DESC -- AGREGADO PARA QUE INGRESE EN ORDEN DE VIGENCIA (GIS 388443)
				-------------------RECORRO LOS COMPONENTES QUE ENCONTRE PARA GUARDARLOS EN LA ACCION NUEVA-------
					SELECT @FILA_INICIO = MIN(FILA), @FILA_FIN = MAX(FILA) FROM @TGFH_APA_Det_Prop_AP_CSal
					/*INSERTAMOS CADA COMPONENTE QUE LA PERSONA TENÍA PREVIAMENTE ASIGNADO EN LA ESTRUCTURA*/
						WHILE @FILA_INICIO <= @FILA_FIN 
						    BEGIN
							IF(SELECT TN_Cod_Componente_Sal FROM @TGFH_APA_Det_Prop_AP_CSal where fila = @fila_inicio) = 5 --SI TRAER DEDICACIÓN EXCLUSIVA
							BEGIN
								SET @TIPO_IDEN  =  ISNULL(CONVERT(VARCHAR,@TN_Tipo_Identificacion), @NULL)
								SET @IDEN	 = ISNULL(@TC_Identificacion_Pro, NULL)
								SET @FECHA  = ISNULL(@InicioVigencia,'19000101')

								SET @DEDICACION_EXCLUS = (SELECT GFH.DBO.FGFH_ESA_CONSULTA_DEDICACION_EXCL_EMP (@TIPO_IDEN,@IDEN,@FECHA) )---ME DICE SI TIENE ESTUDIO DE DEDICACION EXCLUSIVA
							
								IF (@DEDICACION_EXCLUS) = 1 ---SI TIENE ESTUDIO LE AGREGO EL COMPONENTE DE DEDICACION EXCLUSIVA
								BEGIN 
										select @TN_Cod_Componente_Sal_REFJ = TN_Cod_Componente_Sal
											,@TN_Cod_Desg_Comp = TN_Cod_Desg_Comp
											,@TC_Val_Formula = TC_Val_Formula
											,@TN_Anualidades = TN_Anualidades
											,@TN_Ptos_Car_Prof = TN_Ptos_Car_Prof
											,@TF_Anualidad = TF_Anualidad
									from @TGFH_APA_Det_Prop_AP_CSal where fila = @fila_inicio

									SET @SQL  = 'INSERT INTO ' + @TC_Servidor_SIGA + 'TGFH_APA_Det_Prop_AP_CSal /*TGFH_APA_Det_Prop_AP_CSal_Volcado */ ' +
											'(TN_Num_Accion, '+
											'TN_Cod_Componente_Sal, '+
											'TN_Cod_Desg_Comp, '+
											'TC_Val_Formula, '+
											'TN_Anualidades, '+
											'TN_Ptos_Car_Prof, '+
											'TF_Anualidad) '+
									'VALUES(' +CONVERT(VARCHAR,YEAR(@InicioVigencia)) + CONVERT(VARCHAR,@TC_Num_Accion) + ',' + 
											ISNULL(CONVERT(VARCHAR,@TN_Cod_Componente_Sal_REFJ), @NULL)+ ',' + 
											ISNULL(CONVERT(VARCHAR,@TN_Cod_Desg_Comp), @NULL)+ ', ''' + 
											ISNULL(@TC_Val_Formula, @NULL)+ ''' ,' +
											ISNULL(CONVERT(VARCHAR,@TN_Anualidades), @NULL)+ ',' + 
											ISNULL(CONVERT(VARCHAR,@TN_Ptos_Car_Prof), @NULL)+ ',' + 
											ISNULL(' ''' + convert(varchar,@TF_Anualidad,111) + '  ' + convert(varchar,@TF_Anualidad,108) + ''' ', @NULL) +')'
									EXEC(@SQL)    
									SET @FILA_INICIO = @FILA_INICIO + 1
								END--END IF DE DEDICACION
								ELSE
								BEGIN
									SET @FILA_INICIO = @FILA_INICIO + 1
								END
							END--FIN ES DEDICACION EXCLUSIVA
							ELSE
							BEGIN --PREGUNTO SI ES 11 =ZONAJE, 35 = SOBRESUELDO O 48=SOBRESUELDO PROFE---Y NO SE ASIGNAN
							  IF(SELECT TN_Cod_Componente_Sal FROM @TGFH_APA_Det_Prop_AP_CSal where fila = @fila_inicio) = 11 
							     OR (SELECT TN_Cod_Componente_Sal FROM @TGFH_APA_Det_Prop_AP_CSal where fila = @fila_inicio) = 35 
								 OR (SELECT TN_Cod_Componente_Sal FROM @TGFH_APA_Det_Prop_AP_CSal where fila = @fila_inicio) = 48 
							  BEGIN
							     SET @FILA_INICIO = @FILA_INICIO + 1
							  END
							  ELSE
							  BEGIN--TODOS LOS DEMAS SI SE ASIGNAN DE UNA VEZ
								  select @TN_Cod_Componente_Sal_REFJ = TN_Cod_Componente_Sal
										  ,@TN_Cod_Desg_Comp = TN_Cod_Desg_Comp
										  ,@TC_Val_Formula = TC_Val_Formula
										  ,@TN_Anualidades = TN_Anualidades
										  ,@TN_Ptos_Car_Prof = TN_Ptos_Car_Prof
										  ,@TF_Anualidad = TF_Anualidad
									from @TGFH_APA_Det_Prop_AP_CSal where fila = @fila_inicio
									
									IF ((SELECT COUNT(TN_Num_Accion) -- SE AGREGA A LA TABLA SOLO SI NO EXISTE PREVIAMENTE EL REGISTRO PARA EVITAR ERROR DE DUPLICADOS (GIS 388443)
										FROM TGFH_APA_Det_Prop_AP_CSal 
										WHERE	TN_Num_Accion = CONVERT(VARCHAR,YEAR(@InicioVigencia)) + CONVERT(VARCHAR,@TC_Num_Accion) 
											AND TN_Cod_Componente_Sal = @TN_Cod_Componente_Sal_REFJ
											AND	TN_Cod_Desg_Comp = @TN_Cod_Desg_Comp)= 0 ) 
									BEGIN 
										SET @SQL  = 'INSERT INTO ' + @TC_Servidor_SIGA + 'TGFH_APA_Det_Prop_AP_CSal /*TGFH_APA_Det_Prop_AP_CSal_Volcado */ ' +
											 '(TN_Num_Accion, '+
												'TN_Cod_Componente_Sal, '+
												'TN_Cod_Desg_Comp, '+
												'TC_Val_Formula, '+
												'TN_Anualidades, '+
												'TN_Ptos_Car_Prof, '+
												'TF_Anualidad) '+
									   'VALUES(' +CONVERT(VARCHAR,YEAR(@InicioVigencia)) + CONVERT(VARCHAR,@TC_Num_Accion) + ',' + 
											  ISNULL(CONVERT(VARCHAR,@TN_Cod_Componente_Sal_REFJ), @NULL)+ ',' + 
											  ISNULL(CONVERT(VARCHAR,@TN_Cod_Desg_Comp), @NULL)+ ', ''' + 
											  ISNULL(@TC_Val_Formula, @NULL)+ ''' ,' +
											  ISNULL(CONVERT(VARCHAR,@TN_Anualidades), @NULL)+ ',' + 
											  ISNULL(CONVERT(VARCHAR,@TN_Ptos_Car_Prof), @NULL)+ ',' + 
											  ISNULL(' ''' + convert(varchar,@TF_Anualidad,111) + '  ' + convert(varchar,@TF_Anualidad,108) + ''' ', @NULL) +')'
										EXEC(@SQL)
									END -- FIN DE LA VALIDACION PARA EVITAR REPETIDOS (GIS 388443)
									set @FILA_INICIO = @FILA_INICIO + 1
							  END
							END
						END---EN WHILE												
				END 

		    /*SSALGUERAZ/FIN --******************- ESTA SECCION ES PARA MANEJAR LAS PRORROGAS DE NOMBRAMIENTO****************************/		
				
					
					/* --SE COMENTA POR REFORMA FISCAL SSALGUERAZ 04042019
					   SET @TN_Cod_Desg_Comp = isnull(dbo.fObtieneComponenteSalarial(@TN_Num_Puesto, @TN_Cod_Componente_Sal_REFJ, @InicioVigencia, @FinVigencia), 0)

					   if @TN_Cod_Desg_Comp <> 0 begin 
					   --************CAMBIAR A LA CONEXION DE PRODUCCIÓN******			   
						   SET @SQL  = 'INSERT INTO ' + @TC_Servidor_SIGA + 'TGFH_APA_Det_Prop_AP_CSal /*TGFH_APA_Det_Prop_AP_CSal_Volcado */ ' +
								 '(TN_Num_Accion, '+
									'TN_Cod_Componente_Sal, '+
									'TN_Cod_Desg_Comp, '+
									'TC_Val_Formula, '+
									'TN_Anualidades, '+
									'TN_Ptos_Car_Prof, '+
									'TF_Anualidad) '+
						   'VALUES(' +CONVERT(VARCHAR,YEAR(@InicioVigencia)) + CONVERT(VARCHAR,@TC_Num_Accion) + ',' + 
								  ISNULL(CONVERT(VARCHAR,@TN_Cod_Componente_Sal_REFJ), @NULL)+ ',' + 
								  ISNULL(CONVERT(VARCHAR,@TN_Cod_Desg_Comp), @NULL)+ ', ''' + 
								  ISNULL(@TC_Val_Formula, @NULL)+ ''' ,' +
								  ISNULL(CONVERT(VARCHAR,@TN_Anualidades), @NULL)+ ',' + 
								  ISNULL(CONVERT(VARCHAR,@TN_Ptos_Car_Prof), @NULL)+ ',' + 
								  ISNULL(' ''' + convert(varchar,@TF_Anualidad,111) + '  ' + convert(varchar,@TF_Anualidad,108) + ''' ', @NULL) +')'
							  
							--PRINT @SQL     
					    
							EXEC(@SQL)    
						end ---SE COMENTA POR REFORMA FISCAL SSALGUERAZ 04042019 */ 


					/*** INSERTA LOS VALORES EN LA TABLA TGFH_APA_Det_Prop_AP_CSal DEL COMPONENTE ICS ***/
					/*														
					SET @TN_Cod_Desg_Comp = dbo.fObtieneComponenteSalarial(@TN_Num_Puesto, @TN_Cod_Componente_Sal_ICS, @InicioVigencia, @FinVigencia)
					
					--PRINT 'ICS - tracto 1 ' + CONVERT(VARCHAR(20),@TN_Cod_Desg_Comp)
					IF NOT (@TN_Cod_Desg_Comp IS NULL) BEGIN
						
					   SET @SQL  = 'INSERT INTO ' + @TC_Servidor_SIGA + 'TGFH_APA_Det_Prop_AP_CSal /*SJOAPL04.GFH.dbo.TGFH_APA_Det_Prop_AP_CSal*/ ' +
					         '(TN_Num_Accion, ' +
							  '  TN_Cod_Componente_Sal, ' +
							   ' TN_Cod_Desg_Comp, ' +
							    'TC_Val_Formula, ' +
							    'TN_Anualidades, ' +
							    'TN_Ptos_Car_Prof, ' +
							    'TF_Anualidad) ' +
					   'VALUES(' + CONVERT(VARCHAR,YEAR(@TF_Vigencia)) + CONVERT(VARCHAR,@TC_Num_Accion) +', ' +
					          ISNULL(CONVERT(VARCHAR,@TN_Cod_Componente_Sal_ICS), @NULL)+',	' + 
					          ISNULL(CONVERT(VARCHAR,@TN_Cod_Desg_Comp), @NULL)+', ''' +
					          ISNULL(@TC_Val_Formula, @NULL)+''' ,' +
					          ISNULL(CONVERT(VARCHAR,@TN_Anualidades), @NULL)+', '+
					          ISNULL(CONVERT(VARCHAR,@TN_Ptos_Car_Prof), @NULL)+',' +
							  ISNULL(' ''' + convert(varchar,@TF_Anualidad,111) + '  ' + convert(varchar,@TF_Anualidad,108) + ''' ', @NULL) +')'
					          
					    EXEC(@SQL)      
					END
					
					*/
				   	/*** ACTUALIZA EL ESTADO DE LA PROPOSICION PARA DEJARLA PROCESADA  ***/
				
					   UPDATE TGFH_PIN_Proposicion
					   SET TN_Est_Procesada = @TN_Est_Proposicion_Procesada, 
							 TF_Procesada = GETDATE()
--					   WHERE TN_Proposicion = @TN_Proposicion
						WHERE TN_Proposicion = @TN_Proposicion	AND TC_OFICIO = @TC_Oficio
						and tn_cod_ofi_madre = @tn_cod_ofi_madre
			
						INSERT INTO dbo.TGFH_PIN_Proposicion_Accion (
							TN_Proposicion,
							TC_Oficio,
							TN_Cod_Ofi_Madre,
							TN_Num_Accion,
							TF_Procesada,
							TC_Data_Source,
							TC_BaseDatos,
							TN_Motivo, 
							tn_volcado
						) VALUES ( 
							/* TN_Proposicion - decimal(10, 0) */ @TN_Proposicion,
							/* TC_Oficio - varchar(25) */ @TC_Oficio,
							/* TN_Cod_Ofi_Madre - int */ @TN_Cod_Ofi_Madre,
							/* TN_Num_Accion - decimal(10, 0) */ CONVERT(DECIMAL(10,0),CONVERT(VARCHAR(4),YEAR(@InicioVigencia)) + CONVERT(VARCHAR(6),@TC_Num_Accion)),
							/* TF_Procesada - datetime */ GETDATE(),
							/* TC_Data_Source - varchar(50) */ @TC_Data_Source,
							/* TC_BaseDatos - varchar(20) */ @TC_Base_Datos,
							/* TN_Motivo - int */ @TN_Motivo, @tn_volcado ) 
					END
					ELSE BEGIN
			
						/*** INSERTA EN LA TABLA DE ERRORES  ***/		
			
						SET @TN_Num_Error = dbo.fObtenerMaximoError()
			
						INSERT INTO TGFH_PIN_Error_Volcado
			               (TN_Num_Error, 
			                TF_Fecha, 
			                TN_Tipo_Error, 
			                TC_Descripcion,
			                TN_Proposicion, 
							tn_volcado)
						VALUES(@TN_Num_Error, 
								 @TF_Fecha_Hoy, 
								 @TN_Tipo_Error, 
								 @TC_Descripcion + ' ERROR SQL: ' +  CONVERT(VARCHAR(20),@@ERROR),
			                @TN_Proposicion, @tn_volcado)			
			
						/*** ACTUALIZA EL ESTADO DE LA PROPOSICION PARA DEJARLA ERRONEA  ***/
				
					   UPDATE TGFH_PIN_Proposicion
					   SET TN_Est_Procesada = @TN_Est_Proposicion_Erronea
--					   WHERE TN_Proposicion = @TN_Proposicion	
						WHERE TN_Proposicion = @TN_Proposicion	AND TC_OFICIO = @TC_Oficio
						and tn_cod_ofi_madre = @tn_cod_ofi_madre
			
					END
			
				END
				ELSE BEGIN
			
					/*** INSERTA EN LA TABLA DE ERRORES  ***/		
					
						SET @TN_Num_Error = dbo.fObtenerMaximoError()
			
						INSERT INTO TGFH_PIN_Error_Volcado
			               (TN_Num_Error, 
			                TF_Fecha, 
			                TN_Tipo_Error, 
			                TC_Descripcion,
			                TN_Proposicion, tn_volcado)
						VALUES(@TN_Num_Error, 
								 @TF_Fecha_Hoy, 
								 @TN_Tipo_Error, 
								 @TC_Descripcion + ' ERROR SQL: ' +  CONVERT(VARCHAR(20),@@ERROR),
			                @TN_Proposicion, @tn_volcado)			
			
					/*** ACTUALIZA EL ESTADO DE LA PROPOSICION PARA DEJARLA ERRONEA  ***/
			
				   UPDATE TGFH_PIN_Proposicion
				   SET TN_Est_Procesada = @TN_Est_Proposicion_Erronea
--				   WHERE TN_Proposicion = @TN_Proposicion	
					WHERE TN_Proposicion = @TN_Proposicion	AND TC_OFICIO = @TC_Oficio
					and tn_cod_ofi_madre = @tn_cod_ofi_madre
			
			   END

				/*** FIN DE LA MODIFICACION ***/
			
				SET @InicioVigencia = NULL
				SET @FinVigencia = NULL	
			
			/*** SE LIMPIAN LAS VARIABLES ***/
	
		   SET @TC_Identificacion_Est = ''
	  	   SET @TF_Vigencia_Est = ''
		   SET @TF_Fin_Vigencia_Est = ''
		   SET @TN_Num_Puesto_Est = ''
		   SET @TN_Cod_Clase_Est = ''
	
		   /*** TOMA LOS VALORES DE LA SIGUIENTE FILA DEL LISTADO Y LOS ASIGNA A LAS VARIABLES  ***/
				
			FETCH NEXT FROM curEstructura INTO	@TC_Identificacion_Est,
												@TF_Vigencia_Est,
												@TF_Fin_Vigencia_Est,
												@TN_Num_Puesto_Est,
												@TN_Cod_Clase_Est
		END		

	END

	ELSE BEGIN

		--PRINT 'NO TIENE ESTRUCTURA'
		--PRINT ''

		/*** OBTIENE EL SIGUIENTE NUMERO DE CONSECUTIVO  ***/

/*********************************************************************************************************************
*  Código documentado por Luis Quesada -> 16/04/2009

 
		SELECT @TN_Consecutivo = TN_Consecutivo + 1
		FROM GFHvirtual01sql2000.GFH.dbo.TGFH_APA_Consecutivo_AP --TGFH_APA_Consecutivo_AP --
		WHERE TN_Anno_Consecutivo = YEAR(@TF_Vigencia)
	
*/
				SET @TN_Agno = YEAR(@TF_Vigencia)
				
				--************CAMBIAR A LA CONEXION DE PRODUCCIÓN******
				EXEC sp_ConsecutivoGFH @TN_Agno, @TC_Servidor_SIGA, @TN_Consecutivo OUTPUT	
/*********************************************************************************************************************/				

		/*** OBTIENE EL NUMERO DE ACCION A INSERAR  ***/
		
		SELECT @TC_Num_Accion = CASE 
		                        WHEN @TN_Consecutivo < 10 THEN '00000' + CONVERT(Char(1), @TN_Consecutivo) 
		              	     	WHEN @TN_Consecutivo < 100 THEN '0000' + CONVERT(Char(2), @TN_Consecutivo)
				             	WHEN @TN_Consecutivo < 1000 THEN '000' + CONVERT(Char(3), @TN_Consecutivo)
		  		 	            WHEN @TN_Consecutivo < 10000 THEN '00' + CONVERT(Char(4), @TN_Consecutivo)
					            WHEN @TN_Consecutivo < 100000 THEN '0' + CONVERT(Char(5), @TN_Consecutivo)
					            WHEN @TN_Consecutivo < 1000000 THEN CONVERT(Char(6), @TN_Consecutivo) 
			                    END		

	   SET @TN_Tipo_Accion = dbo.fVerificaTipoAccion(@TC_Identificacion_Pro, 
													 @TF_Vigencia, 
													 @TF_Fin_Vigencia,
													 @TN_Cod_Clase,
	                                                 @TN_Num_Puesto)
		/*** VERIFICA SI EL TIPO DE PROPOSICION ES VÁLIDO O ES ERRONEO  ***/
	
		IF @TN_Tipo_Accion <> @TN_Error_Tipo_Accion BEGIN
	
			/*** VERIFICA SI ES UNA PLAZA VACANTE  ***/				   
			

					/********************************************************************************************************/
					--LQM 26/01/2016
/*
			IF @TN_Motivo = 1 OR @TN_Motivo = 32
				SET @TC_Comentarios_CS = 'PLAZA VACANTE' + ' OFICIO: ' + @TC_Oficio				
			 ELSE				
				SET @TC_Comentarios_CS = 'SUSTITUYE A-> CEDULA: ' + @TC_Identificacion_Sust + ' NOMBRE :' + @TC_Nombre_Sust + ' MOTIVO: ' + CASE @TN_Motivo WHEN 1 THEN 'PLAZA VACANTE' WHEN 2 THEN 'VACACIONES' WHEN 3 THEN 'INCAPACIDAD'  WHEN 4 THEN 'PERMISO CON GOCE DE SALARIO'  WHEN 5 THEN 'PERMISO SIN GOCE DE SALARIO' WHEN 6 THEN 'SUSPENSION' WHEN 7 THEN 'ASCENSO A OTRO CARGO' WHEN 8 THEN 'Plaza Extraordinaria' WHEN 9 THEN 'Permiso con sueldo total por beca' END + ' OFICIO: ' + @TC_Oficio 
*/
					select @TC_Comentarios_CS = tc_des_motivo from TGFH_PIN_Motivo_Proposicion where tn_cod_motivo = @TN_Motivo
					set @TC_Comentarios_CS = isnull(@TC_Comentarios_CS, 'Coordinar con TI el tipo de acción')
					IF @TN_Motivo = 1 or @TN_Motivo = 32
						SET @TC_Comentarios_CS = 'PLAZA VACANTE' + ' OFICIO: ' + @TC_Oficio					
					 ELSE				
					 --SET @TC_Comentarios_CS = 'SUSTITUYE A-> CEDULA: ' + @TC_Identificacion_Sust + ' NOMBRE :' + @TC_Nombre_Sust + ' MOTIVO: ' + CASE @TN_Motivo WHEN 1 THEN 'PLAZA VACANTE' WHEN 2 THEN 'VACACIONES' WHEN 3 THEN 'INCAPACIDAD'  WHEN 4 THEN 'PERMISO CON GOCE DE SALARIO'  WHEN 5 THEN 'PERMISO SIN GOCE DE SALARIO' WHEN 6 THEN 'SUSPENSION' WHEN 7 THEN 'ASCENSO A OTRO CARGO' WHEN 8 THEN 'Plaza Extraordinaria' WHEN 9 THEN 'Permiso con sueldo total por beca' ELSE 'PERMISO CON' END + ' OFICIO: ' + @TC_Oficio 
						SET @TC_Comentarios_CS = 'SUSTITUYE A-> CEDULA: ' + @TC_Identificacion_Sust + ' NOMBRE :' + @TC_Nombre_Sust + ' MOTIVO: ' + @TC_Comentarios_CS + ' OFICIO: ' + @TC_Oficio 
						
					set @TC_Comentarios_CS = isnull(@TC_Comentarios_CS, 'Coordinar con TI el tipo de acción')
					/********************************************************************************************************/




			--PRINT ' -----> INSERTAR EN ACCIONES: ' + 'ACCIÓN: ' + CONVERT(VARCHAR,YEAR(@TF_Vigencia)) + CONVERT(VARCHAR,@TC_Num_Accion) + ' TIPO: ' + CONVERT(VARCHAR, @TN_Tipo_Accion) + ' VIGENCIA: ' + CONVERT(VARCHAR,@TF_Vigencia, 103) + ' FIN VIGENCIA: ' + CONVERT(VARCHAR,@TF_Fin_Vigencia, 103)	

			PRINT '<tr><td>' + CONVERT(VARCHAR(20), @TN_Proposicion)  + '</td><td>' +  @TC_Nom_Oficina_Jud  + '</td><td>' +  
		         CASE @TN_Tipo_Accion WHEN 26 THEN 'NOMBRAMIENTO PROPIEDAD' WHEN 28 THEN 'NOMBRAMIENTO INTERINO' WHEN 31 THEN 'ASCENSO PROPIEDAD' WHEN 32 THEN 'ASCENSO INTERINO' WHEN 34 THEN 'DESCENSO PROPIEDAD' WHEN 35 THEN 'DESCENSO INTERINO' WHEN 40 THEN 'TRASLADO INTERINO' WHEN 41 THEN 'TRASLADO PROPIEDAD' END + '</td><td>' + 
		         @TC_Identificacion_Pro + '</td><td>' + @TC_Nombre_Pro + '</td><td>' + 
			      CONVERT(VARCHAR(20), @TF_Vigencia, 103) + ' - ' + CONVERT(VARCHAR(20), @TF_Fin_Vigencia, 103) + '</td><td>' + 
		         @TC_Des_Clase + '</td><td>' + CONVERT(VARCHAR(20), @TN_Num_Puesto) + '</td><td>' + @TC_Comentarios_CS + '</td><td>' + @TC_Comentarios_Oficina + '</td><td>' + 
		         CONVERT(VARCHAR,YEAR(@TF_Vigencia)) + CONVERT(VARCHAR,@TC_Num_Accion) + '</tr>' 


		   /*** INSERTA LOS VALORES EN LA TABLA TGFH_APA_Propuesta_AP  ***/
															/*TGFH_APA_Propuesta_AP_Volcado */
		   --************CAMBIAR A LA CONEXION DE PRODUCCIÓN******												
		   SET @SQL  = 'INSERT INTO ' + @TC_Servidor_SIGA + 'TGFH_APA_Propuesta_AP  ' +
		         '(TN_Num_Accion, TN_Tipo_Identificacion, TC_Identificacion, TN_Tipo_Accion, ' +
			       'TN_Est_Accion, TF_Vigencia, TF_Fin_Vigencia, TN_Cod_Emisor, TC_Num_Acuerdo, ' +
			       'TN_Num_Accion_Anulada, TC_Comentarios_Oficina, TC_Comentarios_CS, TC_Insertado_Por, ' +
			       'TF_Insercion, TC_Modificado_Por, TF_Modificacion) ' +
		   'VALUES(' + CONVERT(VARCHAR,YEAR(@TF_Vigencia)) + CONVERT(VARCHAR,@TC_Num_Accion) + ',' +
			       Isnull(CONVERT(VARCHAR,@TN_Tipo_Identificacion), @NULL)+ ', ''' +  
			       Isnull(@TC_Identificacion_Pro, @NULL)+ ''' ,' +  
			       Isnull(CONVERT(VARCHAR,@TN_Tipo_Accion), @NULL)+ ',' + 
			       Isnull(CONVERT(VARCHAR,@TN_Est_Accion), @NULL)+ ',' + 
				   ISNULL(' ''' + convert(varchar,@TF_Vigencia,111) + '  ' + convert(varchar,@TF_Vigencia,108) + ''' ', @NULL)+ ',' + 
				   ISNULL(' ''' + convert(varchar,@TF_Fin_Vigencia,111) + '  ' + convert(varchar,@TF_Fin_Vigencia,108) + ''' ', @NULL)+ ',' +
			       Isnull(CONVERT(VARCHAR,@TN_Cod_Emisor), @NULL)+ ', ''' + 
			       Isnull(@TC_Num_Acuerdo, @NULL)+ ''' ,' + 
			       Isnull(CONVERT(VARCHAR,@TN_Num_Accion_Anulada), @NULL)+ ', ''' + 
			       Isnull(@TC_Comentarios_Oficina, @NULL)+ ''' , ''' + 
			       Isnull(@TC_Comentarios_CS, @NULL)+ ''' , ''' + 
			       Isnull(@TC_Insertado_Por, @NULL)+ ''' ,' + 
					ISNULL(' ''' + convert(varchar,@TF_Insercion,111) + '  ' + convert(varchar,@TF_Insercion,108) + ''' ', @NULL) + ', ''' +
					ISNULL(@TC_Modificado_Por, @NULL)+ ''' ,' +	
					ISNULL(' ''' + convert(varchar,@TF_Modificacion,111) + '  ' + convert(varchar,@TF_Modificacion,108) + ''' ', @NULL)  + ')'
			--PRINT (@SQL)			       
			
			EXEC(@SQL)  
			IF @@ERROR = 0 BEGIN 
		
			   /*** ACTUALIZA LA TABLA DE CONSECUTIVOS AP CON EL NUEVO NUMERO  ***/
			   
			   --************CAMBIAR A LA CONEXION DE PRODUCCIÓN******
			   SET @SQL  = 'UPDATE ' + @TC_Servidor_SIGA + 'TGFH_APA_Consecutivo_AP ' + 
							'SET TN_Consecutivo = ' + @TC_Num_Accion + 
							' WHERE TN_Anno_Consecutivo = ' + CONVERT(VARCHAR,YEAR(@TF_Vigencia))
							
			   EXEC(@SQL)  	 
			   /*** BUSCA EN LA TABLA DE PUESTOS SI EL PUESTO ES DE 4 O DE 8 HORAS  ***/


/***LQM y DAZ 2017/05/03  para que se analice el motivo de 1/2 tiempo****/
					   --SELECT @TN_Horas_Lab_Dia = TN_Horas_Lab_Dia
					   SELECT @TN_Horas_Lab_Dia = case when @TN_Motivo = 32 then 4 else TN_Horas_Lab_Dia end
					   FROM TGFH_PGA_Puesto
					   WHERE TN_Num_Puesto = @TN_Num_Puesto

					   SELECT @TN_Jornada_Lab_Ini = CASE WHEN @TN_Horas_Lab_Dia = 4 THEN dbo.fVerificaJornadaMedioTiempo(@TC_Identificacion_Pro,  @TF_Vigencia, @TF_Fin_Vigencia) ELSE 1 END
					   SET @TN_Jornada_Lab_Fin = @TN_Jornada_Lab_Ini
					   SET @TN_Jornada_Lab = @TN_Jornada_Lab_Ini
					   
/**********************************************************************/			
			
			   /*** INSERTA LOS VALORES EN LA TABLA TGFH_APA_Det_Prop_AP_Fija  ***/
			   --************CAMBIAR A LA CONEXION DE PRODUCCIÓN******
			   SET @SQL  = 'INSERT INTO ' + @TC_Servidor_SIGA + 'TGFH_APA_Det_Prop_AP_Fija /*TGFH_APA_Det_Prop_AP_Fija_Volcado */ ' +
			         '(TN_Num_Accion, ' +
				        'TN_Cod_Ofi_Judicial, ' +
			 	  		'TN_Jornada_Lab_Ini, ' +
					    'TN_Jornada_Lab_Fin, ' +
					    'TN_Jornada_Lab, ' +
					    'TN_Tipo_Incapacidad, ' +
					    'TN_Num_Puesto, ' +
					    'TN_Cod_Clase, ' +
					    'TN_Forma_Pago, ' +
					    'TN_Periodo_Vacaciones, ' +
					    'TN_Dias_Vacaciones, ' +
					    'TN_Horas_Lab_Dia, ' +
					    'TN_Tipo_Gas_Rep, ' +
					    'TN_Ind_Dias_Naturales, ' +
					    'TL_Ind_Mod_Car_Prof, ' +
					    'TN_Esp_Medc) ' +
			   'VALUES(' + CONVERT(VARCHAR,YEAR(@TF_Vigencia)) + CONVERT(VARCHAR,@TC_Num_Accion) + ', ' +
					    ISNULL(CONVERT(VARCHAR,@TN_Cod_Ofi_Judicial), @NULL)+ ', ' +
					    ISNULL(CONVERT(VARCHAR,@TN_Jornada_Lab_Ini), @NULL)+ ', ' +
					    ISNULL(CONVERT(VARCHAR,@TN_Jornada_Lab_Fin), @NULL)+ ', ' +
					    ISNULL(CONVERT(VARCHAR,@TN_Jornada_Lab), @NULL)+ ', ' +
					    ISNULL(CONVERT(VARCHAR,@TN_Tipo_Incapacidad), @NULL)+ ', ' +
					    ISNULL(CONVERT(VARCHAR,@TN_Num_Puesto), @NULL)+ ', ' +
					    ISNULL(CONVERT(VARCHAR,@TN_Cod_Clase), @NULL)+ ', ' +
					    ISNULL(CONVERT(VARCHAR,@TN_Forma_Pago), @NULL)+ ', ' +
					    ISNULL(CONVERT(VARCHAR,@TN_Periodo_Vacaciones), @NULL)+ ', ' + 
					    ISNULL(CONVERT(VARCHAR,@TN_Dias_Vacaciones), @NULL)+ ', ' +
					    ISNULL(CONVERT(VARCHAR,@TN_Horas_Lab_Dia), @NULL)+ ', ' +
					    ISNULL(CONVERT(VARCHAR,@TN_Tipo_Gas_Rep), @NULL)+ ', ' +
					    ISNULL(CONVERT(VARCHAR,@TN_Ind_Dias_Naturales), @NULL)+ ', ' +
					    ISNULL(CONVERT(VARCHAR,@TL_Ind_Mod_Car_Prof), @NULL)+ ', ' +
					    ISNULL(CONVERT(VARCHAR,@TN_Esp_Medc), @NULL)+ ')'
			  EXEC(@SQL)  
			 /*** INSERTA LOS VALORES EN LA TABLA TGFH_APA_Det_Prop_AP_CSal DEL COMPONENTE REFJ ***/
			
					   /*** INSERTA LOS VALORES EN LA TABLA TGFH_APA_Det_Prop_AP_CSal DEL COMPONENTE REFJ ***/
/*SSALGUERAZ/INICIO --**********************- ESTA SECCION ES PARA MANEJAR LAS PRORROGAS DE NOMBRAMIENTO***************************/
			 
						/************************************************************************************************************************/
						/*** INSERTA LOS VALORES EN LA TABLA TGFH_APA_Det_Prop_AP_CSal cuando es una continuidad del nombramiento ***/
						/*** LQM, 03/06/2019 ***/
						SET @InicioVigencia = @TF_Vigencia
						DELETE FROM @TGFH_APA_Det_Prop_AP_CSal
						IF EXISTS(SELECT TOP 1 1 FROM TGfh_esa_est_sal_emp E
										WHERE   TN_Tipo_Identificacion = ISNULL(CONVERT(VARCHAR,@TN_Tipo_Identificacion), @NULL)
											and TC_Identificacion = ISNULL(@TC_Identificacion_Pro, @NULL)
											and TN_Cod_Clase = ISNULL(CONVERT(VARCHAR,@TN_Cod_Clase), @NULL)
											and TN_Num_Puesto = ISNULL(CONVERT(VARCHAR,@TN_Num_Puesto), @NULL)
											and  CASE 
											       WHEN ISNULL(E.TF_Fin_Vigencia, '1900/01/01') = '1900/01/01' 
												     THEN '2999/12/31' 
												   ELSE E.TF_Fin_Vigencia END = DATEADD(dd, -1, @InicioVigencia) --PREGUNTO SI ES EL ULTIMO DIA
											and ISNULL(CONVERT(VARCHAR,@TN_Cod_Ofi_Judicial), @NULL) = (SELECT TOP 1 TN_Cod_Ofi_Judicial FROM TGfh_pga_puesto_oficina PO WHERE PO.TN_Num_Puesto = E.TN_Num_Puesto AND E.TF_Vigencia BETWEEN PO.TF_Vigencia AND CASE WHEN ISNULL(PO.TF_Fin_Vigencia, '1900/01/01') = '1900/01/01' THEN '2999/12/31' ELSE PO.TF_Fin_Vigencia END)
									)
						BEGIN
						--GUARDO LA ACCION A LA QUE SE LE HACE LA PRORROGA 
						    SET @ACCION_PRORROGA = (SELECT TN_Num_Accion FROM GFH.DBO.TGfh_esa_est_sal_emp E
										WHERE   TN_Tipo_Identificacion = ISNULL(CONVERT(VARCHAR,1), NULL)
											and TC_Identificacion = ISNULL(@TC_Identificacion_Pro, NULL)
											and TN_Cod_Clase = ISNULL(CONVERT(VARCHAR,@TN_Cod_Clase), NULL)
											and TN_Num_Puesto = ISNULL(CONVERT(VARCHAR,@TN_Num_Puesto), @NULL)
											and  CASE 
											       WHEN ISNULL(E.TF_Fin_Vigencia, '1900/01/01') = '1900/01/01' 
												     THEN '2999/12/31' 
												   ELSE E.TF_Fin_Vigencia END = DATEADD(dd, -1, @InicioVigencia) --PREGUNTO SI ES EL ULTIMO DIA
											and ISNULL(CONVERT(VARCHAR,@TN_Cod_Ofi_Judicial), null) = (SELECT TOP 1 TN_Cod_Ofi_Judicial FROM GFH.DBO.TGfh_pga_puesto_oficina PO 
																										WHERE PO.TN_Num_Puesto = E.TN_Num_Puesto AND E.TF_Vigencia BETWEEN PO.TF_Vigencia
																										AND CASE WHEN ISNULL(PO.TF_Fin_Vigencia, '1900/01/01') = '1900/01/01' 
																										THEN '2999/12/31' ELSE PO.TF_Fin_Vigencia END))
			
				------TOMO VIGENCIAS DE LA ACCION QUE SE ESTA PRORROGANDO
						SET @FECHA_INICIO_ACCION_PRORROGADA = (SELECT TF_VIGENCIA FROM GFH.DBO.TGfh_esa_est_sal_emp E WHERE E.TN_Num_Accion = @ACCION_PRORROGA
																				AND  CASE 
																																								WHEN ISNULL(E.TF_Fin_Vigencia, '1900/01/01') = '1900/01/01' 
																																									THEN '2999/12/31' 
																																								ELSE E.TF_Fin_Vigencia END = DATEADD(dd, -1, @InicioVigencia) --PREGUNTO SI ES EL ULTIMO DIA
																																						and ISNULL(CONVERT(VARCHAR,@TN_Cod_Ofi_Judicial), null) = (SELECT TOP 1 TN_Cod_Ofi_Judicial FROM GFH.DBO.TGfh_pga_puesto_oficina PO 
																																																					WHERE PO.TN_Num_Puesto = E.TN_Num_Puesto AND E.TF_Vigencia BETWEEN PO.TF_Vigencia
																																																					AND CASE WHEN ISNULL(PO.TF_Fin_Vigencia, '1900/01/01') = '1900/01/01' 
																																																					THEN '2999/12/31' ELSE PO.TF_Fin_Vigencia END))
						SET @FECHA_FIN_ACCION_PRORROGADA = (SELECT TF_FIN_VIGENCIA FROM GFH.DBO.TGfh_esa_est_sal_emp E WHERE E.TN_Num_Accion = @ACCION_PRORROGA
																				AND  CASE 
																																								WHEN ISNULL(E.TF_Fin_Vigencia, '1900/01/01') = '1900/01/01' 
																																									THEN '2999/12/31' 
																																								ELSE E.TF_Fin_Vigencia END = DATEADD(dd, -1, @InicioVigencia) --PREGUNTO SI ES EL ULTIMO DIA
																																						and ISNULL(CONVERT(VARCHAR,@TN_Cod_Ofi_Judicial), null) = (SELECT TOP 1 TN_Cod_Ofi_Judicial FROM GFH.DBO.TGfh_pga_puesto_oficina PO 
																																																					WHERE PO.TN_Num_Puesto = E.TN_Num_Puesto AND E.TF_Vigencia BETWEEN PO.TF_Vigencia
																																																					AND CASE WHEN ISNULL(PO.TF_Fin_Vigencia, '1900/01/01') = '1900/01/01' 
																																																					THEN '2999/12/31' ELSE PO.TF_Fin_Vigencia END)
						)
						SET @COMENTARIO = (SELECT TC_Comentarios_CS FROM GFH.DBO.TGfh_apa_propuesta_ap WHERE TN_Num_Accion = CONVERT(VARCHAR,YEAR(@InicioVigencia)) + CONVERT(VARCHAR,@TC_Num_Accion) )
			            SET @COMENTARIO =  @COMENTARIO + ' - Prórroga de la acción número = '

				------ACTUALIZO LA PROPUESTA Y LA PONGO APROBADA
			              SET @SQL ='UPDATE TGfh_apa_propuesta_ap' 
						   + ' SET TN_Est_Accion = 2'
						   +', TC_Comentarios_CS =' + CHAR(39) + CAST(ISNULL(@COMENTARIO,'') AS VARCHAR(MAX)) + CAST(@ACCION_PRORROGA AS VARCHAR) + CHAR(39) 
						   + ' WHERE TN_Num_Accion =' + CONVERT(VARCHAR,YEAR(@InicioVigencia)) + CONVERT(VARCHAR,@TC_Num_Accion) 

						  EXEC(@SQL)   
				  -------------------TRAIGO LOS  COMPONENTES	QUE TRAIA LA ACCION QUE SE VA A PRORROGAR------
							INSERT INTO @TGFH_APA_Det_Prop_AP_CSal
								([TN_Num_Accion]			
								,[TN_Cod_Componente_Sal]		
								,[TN_Cod_Desg_Comp]			
								,[TC_Val_Formula]
								,[TN_Anualidades]			
								,[TN_Ptos_Car_Prof]
								,[TF_Anualidad])
							SELECT 0 TN_Num_Accion, A.[TN_Cod_Componente_Sal], [TN_Cod_Desg_Comp],  null TC_Val_Formula, 
									CASE WHEN A.tn_cod_componente_sal = 18 and tn_cod_desg_comp = 1 
										THEN tn_anualidades_cap 
									ELSE tn_anualidades 
									end	[TN_Anualidades]
									,TN_Puntos_Car_Prof
									,null [TF_Anualidad]
									FROM GFH.DBO.TGFH_ESA_CSal_Emp A
									INNER JOIN GFH.DBO.TGFH_ESA_Componente_Sal  b on a.TN_Cod_Componente_Sal = b.TN_Cod_Componente_Sal
									WHERE a.TC_Identificacion = ISNULL(@TC_Identificacion_Pro, @NULL)
									AND A.TN_Tipo_Identificacion = ISNULL(CONVERT(VARCHAR,@TN_Tipo_Identificacion), @NULL)
									AND TF_Vigencia <= @FECHA_FIN_ACCION_PRORROGADA and (TF_Fin_Vigencia >= @FECHA_INICIO_ACCION_PRORROGADA OR isnull(TF_Fin_Vigencia,'19000101') = '19000101') 
									ORDER BY TF_Vigencia DESC -- AGREGADO PARA QUE INGRESE EN ORDEN DE VIGENCIA (GIS 388443)
				-------------------RECORRO LOS COMPONENTES QUE ENCONTRE PARA GUARDARLOS EN LA ACCION NUEVA-------
					SELECT @FILA_INICIO = MIN(FILA), @FILA_FIN = MAX(FILA) FROM @TGFH_APA_Det_Prop_AP_CSal
					/*INSERTAMOS CADA COMPONENTE QUE LA PERSONA TENÍA PREVIAMENTE ASIGNADO EN LA ESTRUCTURA*/
						WHILE @FILA_INICIO <= @FILA_FIN 
						    BEGIN
							IF(SELECT TN_Cod_Componente_Sal FROM @TGFH_APA_Det_Prop_AP_CSal where fila = @fila_inicio) = 5 --SI TRAER DEDICACIÓN EXCLUSIVA
							BEGIN

								SET @TIPO_IDEN  =  ISNULL(CONVERT(VARCHAR,@TN_Tipo_Identificacion), @NULL)
								SET @IDEN	 = ISNULL(@TC_Identificacion_Pro, NULL)
								SET @FECHA  = ISNULL(@InicioVigencia,'19000101')

								SET @DEDICACION_EXCLUS = (SELECT GFH.DBO.FGFH_ESA_CONSULTA_DEDICACION_EXCL_EMP (@TIPO_IDEN,@IDEN,@FECHA) )---ME DICE SI TIENE ESTUDIO DE DEDICACION EXCLUSIVA
							
								IF (@DEDICACION_EXCLUS) = 1 ---SI TIENE ESTUDIO LE AGREGO EL COMPONENTE DE DEDICACION EXCLUSIVA
								BEGIN 
										select @TN_Cod_Componente_Sal_REFJ = TN_Cod_Componente_Sal
											,@TN_Cod_Desg_Comp = TN_Cod_Desg_Comp
											,@TC_Val_Formula = TC_Val_Formula
											,@TN_Anualidades = TN_Anualidades
											,@TN_Ptos_Car_Prof = TN_Ptos_Car_Prof
											,@TF_Anualidad = TF_Anualidad
									from @TGFH_APA_Det_Prop_AP_CSal where fila = @fila_inicio
									
									SET @SQL  = 'INSERT INTO ' + @TC_Servidor_SIGA + 'TGFH_APA_Det_Prop_AP_CSal /*TGFH_APA_Det_Prop_AP_CSal_Volcado */ ' +
											'(TN_Num_Accion, '+
											'TN_Cod_Componente_Sal, '+
											'TN_Cod_Desg_Comp, '+
											'TC_Val_Formula, '+
											'TN_Anualidades, '+
											'TN_Ptos_Car_Prof, '+
											'TF_Anualidad) '+
									'VALUES(' +CONVERT(VARCHAR,YEAR(@InicioVigencia)) + CONVERT(VARCHAR,@TC_Num_Accion) + ',' + 
											ISNULL(CONVERT(VARCHAR,@TN_Cod_Componente_Sal_REFJ), @NULL)+ ',' + 
											ISNULL(CONVERT(VARCHAR,@TN_Cod_Desg_Comp), @NULL)+ ', ''' + 
											ISNULL(@TC_Val_Formula, @NULL)+ ''' ,' +
											ISNULL(CONVERT(VARCHAR,@TN_Anualidades), @NULL)+ ',' + 
											ISNULL(CONVERT(VARCHAR,@TN_Ptos_Car_Prof), @NULL)+ ',' + 
											ISNULL(' ''' + convert(varchar,@TF_Anualidad,111) + '  ' + convert(varchar,@TF_Anualidad,108) + ''' ', @NULL) +')'
									EXEC(@SQL)
									
									SET @FILA_INICIO = @FILA_INICIO + 1
								END--END IF DE DEDICACION
								ELSE
								BEGIN
									SET @FILA_INICIO = @FILA_INICIO + 1
								END
							END--FIN ES DEDICACION EXCLUSIVA
							ELSE
							BEGIN --PREGUNTO SI ES 11 =ZONAJE, 35 = SOBRESUELDO O 48=SOBRESUELDO PROFE---Y NO SE ASIGNAN
							  IF(SELECT TN_Cod_Componente_Sal FROM @TGFH_APA_Det_Prop_AP_CSal where fila = @fila_inicio) = 11 
							     OR (SELECT TN_Cod_Componente_Sal FROM @TGFH_APA_Det_Prop_AP_CSal where fila = @fila_inicio) = 35 
								 OR (SELECT TN_Cod_Componente_Sal FROM @TGFH_APA_Det_Prop_AP_CSal where fila = @fila_inicio) = 48 
							  BEGIN
							     SET @FILA_INICIO = @FILA_INICIO + 1
							  END
							  ELSE
							  BEGIN--TODOS LOS DEMAS SI SE ASIGNAN DE UNA VEZ
								  select @TN_Cod_Componente_Sal_REFJ = TN_Cod_Componente_Sal
										  ,@TN_Cod_Desg_Comp = TN_Cod_Desg_Comp
										  ,@TC_Val_Formula = TC_Val_Formula
										  ,@TN_Anualidades = TN_Anualidades
										  ,@TN_Ptos_Car_Prof = TN_Ptos_Car_Prof
										  ,@TF_Anualidad = TF_Anualidad
									from @TGFH_APA_Det_Prop_AP_CSal where fila = @fila_inicio

									IF ((SELECT COUNT(TN_Num_Accion) -- SE AGREGA A LA TABLA SOLO SI NO EXISTE PREVIAMENTE EL REGISTRO PARA EVITAR ERROR DE DUPLICADOS (GIS 388443)
										FROM TGFH_APA_Det_Prop_AP_CSal 
										WHERE	TN_Num_Accion = CONVERT(VARCHAR,YEAR(@InicioVigencia)) + CONVERT(VARCHAR,@TC_Num_Accion) 
											AND TN_Cod_Componente_Sal = @TN_Cod_Componente_Sal_REFJ
											AND	TN_Cod_Desg_Comp = @TN_Cod_Desg_Comp)= 0 ) 
									BEGIN 
										SET @SQL  = 'INSERT INTO ' + @TC_Servidor_SIGA + 'TGFH_APA_Det_Prop_AP_CSal /*TGFH_APA_Det_Prop_AP_CSal_Volcado */ ' +
											 '(TN_Num_Accion, '+
												'TN_Cod_Componente_Sal, '+
												'TN_Cod_Desg_Comp, '+
												'TC_Val_Formula, '+
												'TN_Anualidades, '+
												'TN_Ptos_Car_Prof, '+
												'TF_Anualidad) '+
									   'VALUES(' +CONVERT(VARCHAR,YEAR(@InicioVigencia)) + CONVERT(VARCHAR,@TC_Num_Accion) + ',' + 
											  ISNULL(CONVERT(VARCHAR,@TN_Cod_Componente_Sal_REFJ), @NULL)+ ',' + 
											  ISNULL(CONVERT(VARCHAR,@TN_Cod_Desg_Comp), @NULL)+ ', ''' + 
											  ISNULL(@TC_Val_Formula, @NULL)+ ''' ,' +
											  ISNULL(CONVERT(VARCHAR,@TN_Anualidades), @NULL)+ ',' + 
											  ISNULL(CONVERT(VARCHAR,@TN_Ptos_Car_Prof), @NULL)+ ',' + 
											  ISNULL(' ''' + convert(varchar,@TF_Anualidad,111) + '  ' + convert(varchar,@TF_Anualidad,108) + ''' ', @NULL) +')'
										EXEC(@SQL)
									END -- FIN DE LA VALIDACION PARA EVITAR REPETIDOS (GIS 388443)
									set @FILA_INICIO = @FILA_INICIO + 1
							  END
							END
						END---EN WHILE												
				END 

		    /*SSALGUERAZ/FIN --******************- ESTA SECCION ES PARA MANEJAR LAS PRORROGAS DE NOMBRAMIENTO****************************/		
	
			/* --SE COMENTA POR REFORMA FISCAL SSALGUERAZ 04042019
			   SET @TN_Cod_Desg_Comp = isnull(dbo.fObtieneComponenteSalarial(@TN_Num_Puesto, @TN_Cod_Componente_Sal_REFJ, @InicioVigencia, @FinVigencia), 0)

			   if @TN_Cod_Desg_Comp <> 0 begin 
				
					--************CAMBIAR A LA CONEXION DE PRODUCCIÓN******	
				   SET @SQL  = 'INSERT INTO ' + @TC_Servidor_SIGA + 'TGFH_APA_Det_Prop_AP_CSal /*TGFH_APA_Det_Prop_AP_CSal_Volcado */ ' + 
						 '(TN_Num_Accion, ' + 
							'TN_Cod_Componente_Sal, ' + 
							'TN_Cod_Desg_Comp, ' + 
							'TC_Val_Formula, ' + 
							'TN_Anualidades, ' + 
							'TN_Ptos_Car_Prof, ' + 
							'TF_Anualidad) ' + 
				   'VALUES(' + CONVERT(VARCHAR,YEAR(@TF_Vigencia)) + CONVERT(VARCHAR,@TC_Num_Accion) + ', ' +
						  ISNULL(CONVERT(VARCHAR,@TN_Cod_Componente_Sal_REFJ), @NULL)+ ', ' +
						  ISNULL(CONVERT(VARCHAR,@TN_Cod_Desg_Comp), @NULL)+ ', ''' +
						  ISNULL(@TC_Val_Formula, @NULL)+ ''' , ' +
						  ISNULL(CONVERT(VARCHAR,@TN_Anualidades), @NULL)+ ', ' +
						  ISNULL(CONVERT(VARCHAR,@TN_Ptos_Car_Prof), @NULL)+ ', ' +
						  ISNULL(' ''' + convert(varchar,@TF_Anualidad,111) + '  ' + convert(varchar,@TF_Anualidad,108) + ''' ', @NULL)+')'
			          
					--PRINT @SQL
				
					EXEC(@SQL) 
				END 
				--SE COMENTA POR REFORMA FISCAL SSALGUERAZ 04042019 */
				
				
				     
			    /*** INSERTA LOS VALORES EN LA TABLA TGFH_APA_Det_Prop_AP_CSal DEL COMPONENTE ICS ***/  
				/*     		        
		       	   SET @TN_Cod_Desg_Comp = dbo.fObtieneComponenteSalarial(@TN_Num_Puesto, @TN_Cod_Componente_Sal_ICS, @TF_Vigencia, @TF_Fin_Vigencia)
		       	   
		       	   --PRINT 'ICS - tracto 1 ' + CONVERT(VARCHAR(20),@TN_Cod_Desg_Comp)
			   IF NOT (@TN_Cod_Desg_Comp IS NULL) BEGIN
					SET @SQL  = 'INSERT INTO ' + @TC_Servidor_SIGA + 'TGFH_APA_Det_Prop_AP_CSal /*SJOAPL04.GFH.dbo.TGFH_APA_Det_Prop_AP_CSal*/ ' +
						'(TN_Num_Accion, ' +
					    'TN_Cod_Componente_Sal, ' +
					    'TN_Cod_Desg_Comp, ' +
					    'TC_Val_Formula, ' +
					    'TN_Anualidades, ' +
					    'TN_Ptos_Car_Prof, ' +
					    'TF_Anualidad) ' +
					'VALUES(' + CONVERT(VARCHAR,YEAR(@TF_Vigencia)) + CONVERT(VARCHAR,@TC_Num_Accion)+ ', ' +
						ISNULL(CONVERT(VARCHAR,@TN_Cod_Componente_Sal_ICS), @NULL)+ ', ' +
						ISNULL(CONVERT(VARCHAR,@TN_Cod_Desg_Comp), @NULL)+ ', ''' +
						ISNULL(@TC_Val_Formula, @NULL)+ ''' , ' +
						ISNULL(CONVERT(VARCHAR,@TN_Anualidades), @NULL)+ ', ' +
						ISNULL(CONVERT(VARCHAR,@TN_Ptos_Car_Prof), @NULL)+ ', ' +
			            ISNULL(' ''' + convert(varchar,@TF_Anualidad,111) + '  ' + convert(varchar,@TF_Anualidad,108) + ''' ', @NULL)+')'

					EXEC(@SQL) 						
				END		   
				*/
		   	/*** ACTUALIZA EL ESTADO DE LA PROPOSICION PARA DEJARLA PROCESADA  ***/
		
			   UPDATE TGFH_PIN_Proposicion
			   SET TN_Est_Procesada = @TN_Est_Proposicion_Procesada, 
                TF_Procesada = GETDATE()
--			   WHERE TN_Proposicion = @TN_Proposicion
			WHERE TN_Proposicion = @TN_Proposicion	AND TC_OFICIO = @TC_Oficio
			and tn_cod_ofi_madre = @tn_cod_ofi_madre
			   
				INSERT INTO dbo.TGFH_PIN_Proposicion_Accion (
					TN_Proposicion,
					TC_Oficio,
					TN_Cod_Ofi_Madre,
					TN_Num_Accion,
					TF_Procesada,
					TC_Data_Source,
					TC_BaseDatos,
					TN_Motivo,
					tn_volcado
				) VALUES ( 
					/* TN_Proposicion - decimal(10, 0) */ @TN_Proposicion,
					/* TC_Oficio - varchar(25) */ @TC_Oficio,
					/* TN_Cod_Ofi_Madre - int */ @TN_Cod_Ofi_Madre,
					/* TN_Num_Accion - decimal(10, 0) */ CONVERT(DECIMAL(10,0),CONVERT(VARCHAR(4),YEAR(@TF_Vigencia)) + CONVERT(VARCHAR(6),@TC_Num_Accion)),
					/* TF_Procesada - datetime */ GETDATE(),
					/* TC_Data_Source - varchar(50) */ @TC_Data_Source,
					/* TC_BaseDatos - varchar(20) */ @TC_Base_Datos,
					/* TN_Motivo - int */ @TN_Motivo, @tn_volcado ) 			   	
			END
			ELSE BEGIN
	
				/*** INSERTA EN LA TABLA DE ERRORES  ***/		

				SET @TN_Num_Error = dbo.fObtenerMaximoError()
	
				INSERT INTO TGFH_PIN_Error_Volcado
	               (TN_Num_Error, 
	                TF_Fecha, 
	                TN_Tipo_Error, 
	                TC_Descripcion,
	                TN_Proposicion, tn_volcado)
				VALUES(@TN_Num_Error, 
						 @TF_Fecha_Hoy, 
						 @TN_Tipo_Error, 
						 @TC_Descripcion + ' ERROR SQL: ' +  CONVERT(VARCHAR(20),@@ERROR),
	                @TN_Proposicion, @tn_volcado)			
	
				/*** ACTUALIZA EL ESTADO DE LA PROPOSICION PARA DEJARLA ERRONEA  ***/
		
			   UPDATE TGFH_PIN_Proposicion
			   SET TN_Est_Procesada = @TN_Est_Proposicion_Erronea
--			   WHERE TN_Proposicion = @TN_Proposicion	
				WHERE TN_Proposicion = @TN_Proposicion	AND TC_OFICIO = @TC_Oficio
				and tn_cod_ofi_madre = @tn_cod_ofi_madre
	
			END
	
		END
		ELSE BEGIN
	
			/*** INSERTA EN LA TABLA DE ERRORES  ***/		
	
				SET @TN_Num_Error = dbo.fObtenerMaximoError()
	
				INSERT INTO TGFH_PIN_Error_Volcado
	               (TN_Num_Error, 
	                TF_Fecha, 
	                TN_Tipo_Error, 
	                TC_Descripcion,
	                TN_Proposicion, tn_volcado)
				VALUES(@TN_Num_Error, 
						 @TF_Fecha_Hoy, 
						 @TN_Tipo_Error, 
						 @TC_Descripcion + ' ERROR SQL: ' +  CONVERT(VARCHAR(20),@@ERROR),
	                @TN_Proposicion, @tn_volcado)			
	
			/*** ACTUALIZA EL ESTADO DE LA PROPOSICION PARA DEJARLA ERRONEA  ***/
	
		   UPDATE TGFH_PIN_Proposicion
		   SET TN_Est_Procesada = @TN_Est_Proposicion_Erronea
--		   WHERE TN_Proposicion = @TN_Proposicion	
			WHERE TN_Proposicion = @TN_Proposicion	AND TC_OFICIO = @TC_Oficio
			and tn_cod_ofi_madre = @tn_cod_ofi_madre
	
	   END

		/*** FIN DE LA MODIFICACION ***/

	END

	CLOSE curEstructura
	DEALLOCATE curEstructura

   /*** TOMA LOS VALORES DE LA SIGUIENTE FILA DEL LISTADO Y LOS ASIGNA A LAS VARIABLES  ***/

	FETCH NEXT FROM curProposiciones INTO	@TN_Proposicion,
   											@TC_Identificacion_Pro,
											@TC_Nombre_Pro,
											@TC_Identificacion_Sust,
											@TC_Nombre_Sust,
											@TN_Motivo,
											@TF_Vigencia,
											@TF_Fin_Vigencia,
											@TC_Comentarios_Oficina,													  
											@TN_Cod_Ofi_Judicial,
											@TC_Nom_Oficina_Jud,
											@TN_Num_Puesto,
											@TN_Cod_Clase,
											@TC_Des_Clase,
											@TC_Oficio,
											@TN_Cod_Ofi_Madre
/***********************************************************************************************
LQM, 28/03/2017 
Tarea 42329:Volcados PIN para extranjeros
***********************************************************************************************/
										, @tn_tipo_identificacion
/***********************************************************************************************/	
END 

/*** CIERRA EL CURSOR ***/

CLOSE curProposiciones
DEALLOCATE curProposiciones

PRINT '</table>'

/*
DELETE FROM TGFH_APA_Det_Prop_AP_Fija_Volcado
DELETE FROM TGFH_APA_Det_Prop_AP_CSal_Volcado
DELETE FROM TGFH_APA_Propuesta_AP_Volcado
DELETE FROM TGFH_PIN_Error_Volcado
*/

/*
SELECT * FROM TGFH_APA_Propuesta_AP_Volcado
SELECT * FROM TGFH_APA_Det_Prop_AP_Fija_Volcado
SELECT * FROM TGFH_APA_Det_Prop_AP_CSal_Volcado
SELECT * FROM TGFH_PIN_Error_Volcado
*/
/*
SELECT COUNT(*) FROM TGFH_APA_Propuesta_AP_Volcado
SELECT COUNT(*) FROM TGFH_APA_Det_Prop_AP_Fija_Volcado
SELECT COUNT(*) FROM TGFH_APA_Det_Prop_AP_CSal_Volcado
SELECT COUNT(*) FROM TGFH_PIN_Error_Volcado
*/

PRINT '<br>'

DECLARE @TC_Motivo AS VARCHAR(50)

DECLARE curProposiciones CURSOR FOR SELECT DISTINCT
					TGFH_PIN_Proposicion.TN_Proposicion,
					TGFH_PIN_Proposicion.TC_Identificacion_Pro,
					TGFH_PIN_Proposicion.TC_Nombre_Pro,
					TGFH_PIN_Proposicion.TC_Identificacion_Sust,
					TGFH_PIN_Proposicion.TC_Nombre_Sust,
					TGFH_PIN_Proposicion.TN_Motivo,
					TGFH_PIN_Proposicion.TF_Vigencia, 
					TGFH_PIN_Proposicion.TF_Fin_Vigencia, 
					TGFH_PIN_Proposicion.TC_Observacion, 
					TGFH_PIN_Proposicion.TN_Cod_Ofi_Hija,
					TGEN_PGA_Oficina_Judicial.TC_Nom_Oficina_Jud, 
					TGFH_PIN_Proposicion.TN_Num_Puesto, 
					TGFH_PIN_Proposicion.TN_Cod_Clase,
					TGFH_PIN_Proposicion.TC_Des_Clase,
					TGFH_PIN_Oficio.TC_Oficio
				    FROM TGFH_PIN_Oficio 
				    INNER JOIN TGFH_PIN_Proposicion ON 
					TGFH_PIN_Oficio.TC_Oficio = TGFH_PIN_Proposicion.TC_Oficio AND 
					TGFH_PIN_Oficio.TN_Cod_Ofi_Judicial = TGFH_PIN_Proposicion.TN_Cod_Ofi_Madre
				    INNER JOIN TGEN_PGA_Oficina_Judicial ON 
					TGFH_PIN_Proposicion.TN_Cod_Ofi_Hija = TGEN_PGA_Oficina_Judicial.TN_Cod_Ofi_Judicial
				    INNER JOIN TGFH_PIN_Error_Volcado ON 
					TGFH_PIN_Error_Volcado.TN_Proposicion = TGFH_PIN_Proposicion.TN_Proposicion
				    WHERE TGFH_PIN_Error_Volcado.TF_Fecha >= CONVERT(DATETIME,GETDATE()-1,102) AND 
					  TGFH_PIN_Error_Volcado.TC_Descripcion = 'ERROR POR DEFINIR (VOLCADO DE PROPOSICIONES) ERROR SQL: 0'			


SET NOCOUNT ON

PRINT '<table border = 0 align = "center"><tr><td align = "center"><h1>REPORTE DE INCONSISTENCIAS DE PROPOSICIONES AL: ' + CONVERT(VARCHAR(20),GETDATE(),103) + '</h1></td></tr></table>'

/*** ABRE EL CURSOR ***/

OPEN curProposiciones

/*** TOMA LOS VALORES DE LA PRIMERA FILA DEL LISTADO Y LOS ASIGNA A LAS VARIABLES  ***/

FETCH NEXT FROM curProposiciones INTO @TN_Proposicion,
                                      @TC_Identificacion_Pro,
				      @TC_Nombre_Pro,
				      @TC_Identificacion_Sust,
				      @TC_Nombre_Sust,
				      @TN_Motivo,
				      @TF_Vigencia,
				      @TF_Fin_Vigencia,
				      @TC_Comentarios_Oficina,
				      @TN_Cod_Ofi_Judicial,
				      @TC_Nom_Oficina_Jud,
				      @TN_Num_Puesto,
			 	      @TN_Cod_Clase,	
				      @TC_Des_Clase,
				      @TC_Oficio


PRINT '<table border = 1><tr><td>PROPOSICION</td><td>OFICINA</td><td>CEDULA PRO</td><td>NOMBRE PRO</td><td>PERIODO</td><td>CLASE PUESTO</td><td>NUM PUESTO</td><td>COMENTARIO</td><td>COMENTARIO OFICINA</td></tr>'

/*** CICLO DEL CURSOR ***/

WHILE @@FETCH_STATUS = 0 BEGIN

   SELECT @TC_Motivo = CASE @TN_Motivo
	  WHEN 1 THEN 'Plaza Vacante'
	  WHEN 2 THEN 'Vacaciones'
	  WHEN 3 THEN 'Incapacidad'
	  WHEN 4 THEN 'Permiso con goce de salario'
	  WHEN 5 THEN 'Permiso sin goce de salario'
/*Tarea 42555 - LQM, 11/09/2017*/
--	  WHEN 6 THEN 'Suspensión'
WHEN 6 THEN 'Suspensión con goce de Salario'
WHEN 28 THEN 'Suspensión sin goce de Salario'
/********************************/
	  WHEN 7 THEN 'Ascenso o pasó a otro cargo' 
	  END

   IF @TN_Motivo = 1 OR @TN_Motivo = 32
      SET @TC_Comentarios_CS = 'PLAZA VACANTE' + ' OFICIO: ' + @TC_Oficio
   ELSE				
	  SET @TC_Comentarios_CS = 'SUSTITUYE A-> CEDULA: ' + @TC_Identificacion_Sust + ' NOMBRE :' + @TC_Nombre_Sust + ' MOTIVO: ' + CASE @TN_Motivo WHEN 1 THEN 'PLAZA VACANTE' WHEN 2 THEN 'VACACIONES' WHEN 3 THEN 'INCAPACIDAD'  WHEN 4 THEN 'PERMISO CON GOCE DE SALARIO'  WHEN 5 THEN 'PERMISO SIN GOCE DE SALARIO' WHEN 6 THEN 'SUSPENSION CON GOE DE SALARIO' WHEN 7 THEN 'ASCENSO A OTRO CARGO' WHEN 8 THEN 'Plaza Extraordinaria' WHEN 9 THEN 'Permiso con sueldo total por beca' WHEN 28 THEN 'SUSPENSION SIN GOCE DE SALARIO' END + ' OFICIO: ' + @TC_Oficio 
      

   PRINT '<tr><td>' + CONVERT(VARCHAR(20), @TN_Proposicion)  + 
         '</td><td>' +  @TC_Nom_Oficina_Jud  + 
 	 '</td><td>' + @TC_Identificacion_Pro + 
 	 '</td><td>' + @TC_Nombre_Pro + 
 	 '</td><td>' + CONVERT(VARCHAR(20), @TF_Vigencia, 103) + ' - ' + CONVERT(VARCHAR(20), @TF_Fin_Vigencia, 103) + 
 	 '</td><td>' + @TC_Des_Clase + 
 	 '</td><td>' + CONVERT(VARCHAR(20), @TN_Num_Puesto) + 
	 '</td><td>' + @TC_Comentarios_CS +
	 '</td><td>' + @TC_Comentarios_Oficina + '</tr>'
	 

  /*** TOMA LOS VALORES DE LA SIGUIENTE FILA DEL LISTADO Y LOS ASIGNA A LAS VARIABLES  ***/

   FETCH NEXT FROM curProposiciones INTO @TN_Proposicion,
                                         @TC_Identificacion_Pro,
					 @TC_Nombre_Pro,
					 @TC_Identificacion_Sust,
					 @TC_Nombre_Sust,
					 @TN_Motivo,
				         @TF_Vigencia,
				      	 @TF_Fin_Vigencia,
				     	 @TC_Comentarios_Oficina,
				     	 @TN_Cod_Ofi_Judicial,
					 @TC_Nom_Oficina_Jud,
				     	 @TN_Num_Puesto,
			 	    	 @TN_Cod_Clase,	
					 @TC_Des_Clase,
					 @TC_Oficio

END 

/*** CIERRA EL CURSOR ***/

CLOSE curProposiciones
DEALLOCATE curProposiciones

PRINT '</table>'


/******************************************************************************************************/
--Iniciamos el proceso asignando un nuevo código de volcado.
update tgfh_pin_volcado
set tf_fecha_fin = getdate()
where tn_volcado = @tn_volcado

/******************************************************************************************************/
