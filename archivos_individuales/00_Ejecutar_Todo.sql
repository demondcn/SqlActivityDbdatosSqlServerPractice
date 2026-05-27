/*
    Ejercicios F, G, H e I
    Script T-SQL para abrir y ejecutar en SQL Server Management Studio.

    Instrucciones:
    1. Abrir este archivo en SQL Server Management Studio.
    2. Ejecutar todo el script con F5.
    3. Revisar las consultas de prueba al final.
*/

IF DB_ID(N'ActividadSQL') IS NULL
BEGIN
    CREATE DATABASE ActividadSQL;
END
GO

USE ActividadSQL;
GO

/* Limpieza para poder ejecutar el script varias veces */
IF OBJECT_ID(N'dbo.sp_MatricularEstudiante', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_MatricularEstudiante;
GO

IF OBJECT_ID(N'dbo.sp_TransferirDinero', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_TransferirDinero;
GO

IF OBJECT_ID(N'dbo.sp_RegistrarVentaConControlStock', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RegistrarVentaConControlStock;
GO

IF OBJECT_ID(N'dbo.sp_DescontarStockEnVenta', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_DescontarStockEnVenta;
GO

IF OBJECT_ID(N'dbo.Matricula', N'U') IS NOT NULL
    DROP TABLE dbo.Matricula;
GO

IF OBJECT_ID(N'dbo.Materia', N'U') IS NOT NULL
    DROP TABLE dbo.Materia;
GO

IF OBJECT_ID(N'dbo.Estudiante', N'U') IS NOT NULL
    DROP TABLE dbo.Estudiante;
GO

IF OBJECT_ID(N'dbo.Venta', N'U') IS NOT NULL
    DROP TABLE dbo.Venta;
GO

IF OBJECT_ID(N'dbo.Producto', N'U') IS NOT NULL
    DROP TABLE dbo.Producto;
GO

IF OBJECT_ID(N'dbo.Cuenta', N'U') IS NOT NULL
    DROP TABLE dbo.Cuenta;
GO

/* Tablas base para ventas */
CREATE TABLE dbo.Producto
(
    IdProducto INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Producto PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Precio DECIMAL(10,2) NOT NULL,
    Stock INT NOT NULL
);
GO

CREATE TABLE dbo.Venta
(
    IdVenta INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Venta PRIMARY KEY,
    IdProducto INT NOT NULL,
    CantidadVendida INT NOT NULL,
    PrecioUnitario DECIMAL(10,2) NOT NULL,
    FechaVenta DATETIME NOT NULL CONSTRAINT DF_Venta_FechaVenta DEFAULT GETDATE(),
    CONSTRAINT FK_Venta_Producto
        FOREIGN KEY (IdProducto) REFERENCES dbo.Producto(IdProducto)
);
GO

INSERT INTO dbo.Producto (Nombre, Precio, Stock)
VALUES
    ('Teclado', 55000.00, 10),
    ('Mouse', 30000.00, 5),
    ('Monitor', 480000.00, 3);
GO

/* ============================================================
   Ejercicio F: Procedimiento para descontar stock en venta
   ============================================================ */
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

    UPDATE dbo.Producto
    SET Stock = Stock - @CantidadVendida
    WHERE IdProducto = @IdProducto;

    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR('El producto indicado no existe.', 16, 1);
        RETURN;
    END;
END;
GO

/* ============================================================
   Ejercicio G: Transaccion de venta con control de stock
   ============================================================ */
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
        FROM dbo.Producto WITH (UPDLOCK, HOLDLOCK)
        WHERE IdProducto = @IdProducto;

        IF @PrecioUnitario IS NULL
        BEGIN
            RAISERROR('El producto indicado no existe.', 16, 1);
        END;

        INSERT INTO dbo.Venta (IdProducto, CantidadVendida, PrecioUnitario)
        VALUES (@IdProducto, @CantidadVendida, @PrecioUnitario);

        UPDATE dbo.Producto
        SET Stock = Stock - @CantidadVendida
        WHERE IdProducto = @IdProducto;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.Producto
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

/* ============================================================
   Ejercicio H: Transaccion bancaria simple
   ============================================================ */
CREATE TABLE dbo.Cuenta
(
    IdCuenta INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Cuenta PRIMARY KEY,
    Titular VARCHAR(100) NOT NULL,
    Saldo DECIMAL(12,2) NOT NULL
);
GO

INSERT INTO dbo.Cuenta (Titular, Saldo)
VALUES
    ('Ana Perez', 500000.00),
    ('Carlos Gomez', 120000.00);
GO

CREATE PROCEDURE dbo.sp_TransferirDinero
    @IdCuentaOrigen INT,
    @IdCuentaDestino INT,
    @Monto DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @SaldoOrigen DECIMAL(12,2);

        IF @Monto <= 0
        BEGIN
            RAISERROR('El monto debe ser mayor que cero.', 16, 1);
        END;

        IF @IdCuentaOrigen = @IdCuentaDestino
        BEGIN
            RAISERROR('La cuenta origen y destino no pueden ser la misma.', 16, 1);
        END;

        SELECT @SaldoOrigen = Saldo
        FROM dbo.Cuenta WITH (UPDLOCK, HOLDLOCK)
        WHERE IdCuenta = @IdCuentaOrigen;

        IF @SaldoOrigen IS NULL
        BEGIN
            RAISERROR('La cuenta origen no existe.', 16, 1);
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Cuenta WITH (UPDLOCK, HOLDLOCK)
            WHERE IdCuenta = @IdCuentaDestino
        )
        BEGIN
            RAISERROR('La cuenta destino no existe.', 16, 1);
        END;

        IF @SaldoOrigen < @Monto
        BEGIN
            RAISERROR('La cuenta origen no tiene fondos suficientes.', 16, 1);
        END;

        UPDATE dbo.Cuenta
        SET Saldo = Saldo - @Monto
        WHERE IdCuenta = @IdCuentaOrigen;

        UPDATE dbo.Cuenta
        SET Saldo = Saldo + @Monto
        WHERE IdCuenta = @IdCuentaDestino;

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

/* ============================================================
   Ejercicio I: Sistema de matriculas academicas
   ============================================================ */
CREATE TABLE dbo.Estudiante
(
    IdEstudiante INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Estudiante PRIMARY KEY,
    Documento VARCHAR(30) NOT NULL CONSTRAINT UQ_Estudiante_Documento UNIQUE,
    Nombre VARCHAR(100) NOT NULL,
    FechaRegistro DATETIME NOT NULL CONSTRAINT DF_Estudiante_FechaRegistro DEFAULT GETDATE()
);
GO

CREATE TABLE dbo.Materia
(
    IdMateria INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Materia PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    CupoDisponible INT NOT NULL
);
GO

CREATE TABLE dbo.Matricula
(
    IdMatricula INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Matricula PRIMARY KEY,
    IdEstudiante INT NOT NULL,
    IdMateria INT NOT NULL,
    FechaMatricula DATETIME NOT NULL CONSTRAINT DF_Matricula_FechaMatricula DEFAULT GETDATE(),
    CONSTRAINT FK_Matricula_Estudiante
        FOREIGN KEY (IdEstudiante) REFERENCES dbo.Estudiante(IdEstudiante),
    CONSTRAINT FK_Matricula_Materia
        FOREIGN KEY (IdMateria) REFERENCES dbo.Materia(IdMateria),
    CONSTRAINT UQ_Matricula_EstudianteMateria
        UNIQUE (IdEstudiante, IdMateria)
);
GO

INSERT INTO dbo.Materia (Nombre, CupoDisponible)
VALUES
    ('Bases de Datos', 2),
    ('Programacion', 1);
GO

CREATE PROCEDURE dbo.sp_MatricularEstudiante
    @Documento VARCHAR(30),
    @NombreEstudiante VARCHAR(100),
    @IdMateria INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @IdEstudiante INT;

        IF LTRIM(RTRIM(@Documento)) = ''
        BEGIN
            RAISERROR('El documento del estudiante es obligatorio.', 16, 1);
        END;

        IF LTRIM(RTRIM(@NombreEstudiante)) = ''
        BEGIN
            RAISERROR('El nombre del estudiante es obligatorio.', 16, 1);
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Materia WITH (UPDLOCK, HOLDLOCK)
            WHERE IdMateria = @IdMateria
        )
        BEGIN
            RAISERROR('La materia indicada no existe.', 16, 1);
        END;

        SELECT @IdEstudiante = IdEstudiante
        FROM dbo.Estudiante
        WHERE Documento = @Documento;

        IF @IdEstudiante IS NULL
        BEGIN
            INSERT INTO dbo.Estudiante (Documento, Nombre)
            VALUES (@Documento, @NombreEstudiante);

            SET @IdEstudiante = SCOPE_IDENTITY();
        END;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.Matricula
            WHERE IdEstudiante = @IdEstudiante
              AND IdMateria = @IdMateria
        )
        BEGIN
            RAISERROR('El estudiante ya esta matriculado en esta materia.', 16, 1);
        END;

        INSERT INTO dbo.Matricula (IdEstudiante, IdMateria)
        VALUES (@IdEstudiante, @IdMateria);

        UPDATE dbo.Materia
        SET CupoDisponible = CupoDisponible - 1
        WHERE IdMateria = @IdMateria;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.Materia
            WHERE IdMateria = @IdMateria
              AND CupoDisponible < 0
        )
        BEGIN
            RAISERROR('No hay cupo disponible. Matricula cancelada.', 16, 1);
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

/* ============================================================
   Pruebas exitosas
   ============================================================ */

-- Ejercicio F
EXEC dbo.sp_DescontarStockEnVenta @IdProducto = 1, @CantidadVendida = 2;
SELECT 'Productos despues del Ejercicio F' AS Resultado;
SELECT * FROM dbo.Producto;
GO

-- Ejercicio G
EXEC dbo.sp_RegistrarVentaConControlStock @IdProducto = 2, @CantidadVendida = 2;
SELECT 'Ventas y productos despues del Ejercicio G' AS Resultado;
SELECT * FROM dbo.Venta;
SELECT * FROM dbo.Producto;
GO

-- Ejercicio H
EXEC dbo.sp_TransferirDinero @IdCuentaOrigen = 1, @IdCuentaDestino = 2, @Monto = 75000.00;
SELECT 'Cuentas despues del Ejercicio H' AS Resultado;
SELECT * FROM dbo.Cuenta;
GO

-- Ejercicio I
EXEC dbo.sp_MatricularEstudiante
    @Documento = '1001',
    @NombreEstudiante = 'Laura Martinez',
    @IdMateria = 1;

SELECT 'Matriculas despues del Ejercicio I' AS Resultado;
SELECT * FROM dbo.Estudiante;
SELECT * FROM dbo.Materia;
SELECT * FROM dbo.Matricula;
GO

/* ============================================================
   Pruebas opcionales de error y ROLLBACK
   Quitar los comentarios para probarlas una por una.
   ============================================================ */

-- Ejercicio G: debe fallar y deshacer la venta porque no hay stock.
-- EXEC dbo.sp_RegistrarVentaConControlStock @IdProducto = 3, @CantidadVendida = 100;
-- SELECT * FROM dbo.Venta;
-- SELECT * FROM dbo.Producto;

-- Ejercicio H: debe fallar y conservar los saldos porque no hay fondos.
-- EXEC dbo.sp_TransferirDinero @IdCuentaOrigen = 2, @IdCuentaDestino = 1, @Monto = 999999.00;
-- SELECT * FROM dbo.Cuenta;

-- Ejercicio I: debe fallar cuando se acabe el cupo.
-- EXEC dbo.sp_MatricularEstudiante @Documento = '1002', @NombreEstudiante = 'Diego Ruiz', @IdMateria = 2;
-- EXEC dbo.sp_MatricularEstudiante @Documento = '1003', @NombreEstudiante = 'Maria Lopez', @IdMateria = 2;
-- SELECT * FROM dbo.Estudiante;
-- SELECT * FROM dbo.Materia;
-- SELECT * FROM dbo.Matricula;
