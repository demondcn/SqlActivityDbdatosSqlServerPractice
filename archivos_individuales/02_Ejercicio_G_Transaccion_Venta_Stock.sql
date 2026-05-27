/*
    Ejercicio G - Transaccion de venta con control de stock
    Abrir en SQL Server Management Studio y ejecutar con F5.
*/

IF DB_ID(N'ActividadSQL') IS NULL
BEGIN
    CREATE DATABASE ActividadSQL;
END
GO

USE ActividadSQL;
GO

IF OBJECT_ID(N'dbo.sp_RegistrarVentaConControlStock', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RegistrarVentaConControlStock;
GO

IF OBJECT_ID(N'dbo.Venta_G', N'U') IS NOT NULL
    DROP TABLE dbo.Venta_G;
GO

IF OBJECT_ID(N'dbo.Producto_G', N'U') IS NOT NULL
    DROP TABLE dbo.Producto_G;
GO

CREATE TABLE dbo.Producto_G
(
    IdProducto INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Producto_G PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Precio DECIMAL(10,2) NOT NULL,
    Stock INT NOT NULL
);
GO

CREATE TABLE dbo.Venta_G
(
    IdVenta INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Venta_G PRIMARY KEY,
    IdProducto INT NOT NULL,
    CantidadVendida INT NOT NULL,
    PrecioUnitario DECIMAL(10,2) NOT NULL,
    FechaVenta DATETIME NOT NULL CONSTRAINT DF_Venta_G_FechaVenta DEFAULT GETDATE(),
    CONSTRAINT FK_Venta_G_Producto_G
        FOREIGN KEY (IdProducto) REFERENCES dbo.Producto_G(IdProducto)
);
GO

INSERT INTO dbo.Producto_G (Nombre, Precio, Stock)
VALUES
    ('Teclado', 55000.00, 10),
    ('Mouse', 30000.00, 5),
    ('Monitor', 480000.00, 3);
GO

CREATE PROCEDURE dbo.sp_RegistrarVentaConControlStock
    @IdProducto INT,
    @CantidadVendida INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @PrecioUnitario DECIMAL(10,2);

        IF @CantidadVendida <= 0
        BEGIN
            RAISERROR('La cantidad vendida debe ser mayor que cero.', 16, 1);
        END;

        SELECT @PrecioUnitario = Precio
        FROM dbo.Producto_G WITH (UPDLOCK, HOLDLOCK)
        WHERE IdProducto = @IdProducto;

        IF @PrecioUnitario IS NULL
        BEGIN
            RAISERROR('El producto indicado no existe.', 16, 1);
        END;

        INSERT INTO dbo.Venta_G (IdProducto, CantidadVendida, PrecioUnitario)
        VALUES (@IdProducto, @CantidadVendida, @PrecioUnitario);

        UPDATE dbo.Producto_G
        SET Stock = Stock - @CantidadVendida
        WHERE IdProducto = @IdProducto;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.Producto_G
            WHERE IdProducto = @IdProducto
              AND Stock < 0
        )
        BEGIN
            RAISERROR('El stock resultante queda negativo. Venta cancelada.', 16, 1);
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        DECLARE @MensajeError VARCHAR(4000);
        SET @MensajeError = ERROR_MESSAGE();

        RAISERROR(@MensajeError, 16, 1);
    END CATCH;
END;
GO

/* Prueba exitosa */
EXEC dbo.sp_RegistrarVentaConControlStock
    @IdProducto = 1,
    @CantidadVendida = 2;

SELECT 'Ventas registradas' AS Resultado;
SELECT * FROM dbo.Venta_G;

SELECT 'Productos despues de la venta' AS Resultado;
SELECT * FROM dbo.Producto_G;
GO

/* Prueba opcional de ROLLBACK: quitar comentario para probar */
-- EXEC dbo.sp_RegistrarVentaConControlStock @IdProducto = 3, @CantidadVendida = 100;
-- SELECT * FROM dbo.Venta_G;
-- SELECT * FROM dbo.Producto_G;
