ARCHIVOS PARA ABRIR EN SQL SERVER MANAGEMENT STUDIO

Carpeta:
C:\Users\demondcn\Downloads\anderson proyect\ActividadSQL\archivos_individuales

Puedes abrir cualquier archivo .sql en SQL Server Management Studio:

1. Abrir SQL Server Management Studio.
2. Ir a File > Open > File.
3. Seleccionar el archivo .sql.
4. Ejecutar con F5.

Archivos incluidos:

01_Ejercicio_F_Descontar_Stock.sql
Procedimiento que recibe IdProducto y CantidadVendida, y descuenta stock.

02_Ejercicio_G_Transaccion_Venta_Stock.sql
Transaccion que inserta una venta y actualiza stock. Si el stock queda negativo,
hace ROLLBACK.

03_Ejercicio_H_Transaccion_Bancaria.sql
Tabla Cuenta y transaccion para transferir dinero entre cuentas, validando fondos.

04_Ejercicio_I_Sistema_Matriculas.sql
Sistema de matriculas con estudiante, materia, cupo disponible y ROLLBACK si no hay cupo.

00_Ejecutar_Todo.sql
Archivo maestro con todos los ejercicios en un solo script.
Para usarlo en SSMS debes activar Query > SQLCMD Mode.

Si quieres ejecutar todo sin activar SQLCMD Mode, usa este archivo:
C:\Users\demondcn\Downloads\anderson proyect\ActividadSQL\ejercicios_F_G_H_I.sql
