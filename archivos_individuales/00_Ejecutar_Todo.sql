/*
    Archivo maestro para SQL Server Management Studio.
    Ejecuta todos los ejercicios F, G, H e I en una sola vez.

    IMPORTANTE:
    Este archivo usa comandos :r de SQLCMD.
    En SSMS activa Query > SQLCMD Mode antes de ejecutar.

    Si no quieres activar SQLCMD Mode, abre y ejecuta este archivo:
    C:\Users\demondcn\Downloads\anderson proyect\ActividadSQL\ejercicios_F_G_H_I.sql
*/

:r "C:\Users\demondcn\Downloads\anderson proyect\ActividadSQL\archivos_individuales\01_Ejercicio_F_Descontar_Stock.sql"
:r "C:\Users\demondcn\Downloads\anderson proyect\ActividadSQL\archivos_individuales\02_Ejercicio_G_Transaccion_Venta_Stock.sql"
:r "C:\Users\demondcn\Downloads\anderson proyect\ActividadSQL\archivos_individuales\03_Ejercicio_H_Transaccion_Bancaria.sql"
:r "C:\Users\demondcn\Downloads\anderson proyect\ActividadSQL\archivos_individuales\04_Ejercicio_I_Sistema_Matriculas.sql"

PRINT 'Todos los ejercicios fueron ejecutados.';
GO
