/*
    Ejercicio H - Transaccion bancaria simple
    Abrir en SQL Server Management Studio y ejecutar con F5.
*/

IF DB_ID(N'ActividadSQL') IS NULL
BEGIN
    CREATE DATABASE ActividadSQL;
END
GO

USE ActividadSQL;
GO

IF OBJECT_ID(N'dbo.sp_TransferirDinero', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_TransferirDinero;
GO

IF OBJECT_ID(N'dbo.Cuenta', N'U') IS NOT NULL
    DROP TABLE dbo.Cuenta;
GO

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

/* Prueba exitosa */
SELECT 'Cuentas antes de la transferencia' AS Resultado;
SELECT * FROM dbo.Cuenta;

EXEC dbo.sp_TransferirDinero
    @IdCuentaOrigen = 1,
    @IdCuentaDestino = 2,
    @Monto = 75000.00;

SELECT 'Cuentas despues de la transferencia' AS Resultado;
SELECT * FROM dbo.Cuenta;
GO

/* Prueba opcional de ROLLBACK: quitar comentario para probar */
-- EXEC dbo.sp_TransferirDinero @IdCuentaOrigen = 2, @IdCuentaDestino = 1, @Monto = 999999.00;
-- SELECT * FROM dbo.Cuenta;
