CREATE OR ALTER PROCEDURE cost.deleteCurrentPeriod @period INT
AS
BEGIN
    DECLARE @datePeriod DATE = DATEADD(MONTH, @period, GETDATE());

    IF @period BETWEEN -12 AND 0
    BEGIN
        -- Elimina registros del periodo especificado, modificar el nombre de la tabla de ser necesario
        DELETE FROM cost.consumoAzure
        WHERE YEAR([Date]) = YEAR(@datePeriod)
          AND MONTH([Date]) = MONTH(@datePeriod);

       END
    ELSE
    BEGIN
        SELECT 'Parámetro inválido. Debe estar entre -12 y 0.' AS Mensaje;
    END
END;