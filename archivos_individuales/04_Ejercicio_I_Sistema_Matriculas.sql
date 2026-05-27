/*
    Ejercicio I - Sistema de matriculas academicas
    Abrir en SQL Server Management Studio y ejecutar con F5.
*/

IF DB_ID(N'ActividadSQL') IS NULL
BEGIN
    CREATE DATABASE ActividadSQL;
END
GO

USE ActividadSQL;
GO

IF OBJECT_ID(N'dbo.sp_MatricularEstudiante', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_MatricularEstudiante;
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

/* Prueba exitosa */
EXEC dbo.sp_MatricularEstudiante
    @Documento = '1001',
    @NombreEstudiante = 'Laura Martinez',
    @IdMateria = 1;

SELECT 'Estudiantes' AS Resultado;
SELECT * FROM dbo.Estudiante;

SELECT 'Materias' AS Resultado;
SELECT * FROM dbo.Materia;

SELECT 'Matriculas' AS Resultado;
SELECT * FROM dbo.Matricula;
GO

/* Prueba opcional de ROLLBACK: quitar comentario para probar */
-- EXEC dbo.sp_MatricularEstudiante @Documento = '1002', @NombreEstudiante = 'Diego Ruiz', @IdMateria = 2;
-- EXEC dbo.sp_MatricularEstudiante @Documento = '1003', @NombreEstudiante = 'Maria Lopez', @IdMateria = 2;
-- SELECT * FROM dbo.Estudiante;
-- SELECT * FROM dbo.Materia;
-- SELECT * FROM dbo.Matricula;
