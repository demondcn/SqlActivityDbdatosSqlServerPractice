/*
    Ejercicio F - Procedimiento: descontar stock en venta
    Abrir en SQL Server Management Studio y ejecutar con F5.
*/

IF DB_ID(N'ActividadSQL') IS NULL
BEGIN
    CREATE DATABASE ActividadSQL;
END
GO

USE ActividadSQL;
GO

IF OBJECT_ID(N'dbo.sp_DescontarStockEnVenta', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_DescontarStockEnVenta;
GO

IF OBJECT_ID(N'dbo.Producto_F', N'U') IS NOT NULL
    DROP TABLE dbo.Producto_F;
GO

CREATE TABLE dbo.Producto_F
(
    IdProducto INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Producto_F PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Stock INT NOT NULL
);
GO

INSERT INTO dbo.Producto_F (Nombre, Stock)
VALUES
    ('Teclado', 10),
    ('Mouse', 5),
    ('Monitor', 3);
GO

CREATE PROCEDURE dbo.sp_DescontarStockEnVenta
    @IdProducto INT,
    @CantidadVendida INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @CantidadVendida <= 0
    BEGIN
        RAISERROR('La cantidad vendida debe ser mayor que cero.', 16, 1);
        RETURN;
    END;

    UPDATE dbo.Producto_F
    SET Stock = Stock - @CantidadVendida
    WHERE IdProducto = @IdProducto;

    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR('El producto indicado no existe.', 16, 1);
        RETURN;
    END;
END;
GO

/* Prueba */
SELECT 'Stock antes de vender' AS Resultado;
SELECT * FROM dbo.Producto_F;

EXEC dbo.sp_DescontarStockEnVenta
    @IdProducto = 1,
    @CantidadVendida = 2;

SELECT 'Stock despues de vender' AS Resultado;
SELECT * FROM dbo.Producto_F;
GO
