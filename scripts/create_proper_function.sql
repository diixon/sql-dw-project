/*
===============================================================================
Function: dbo.fn_ProperCase
===============================================================================
Purpose:
    Converts a string to "proper case" (a.k.a. title case), capitalizing the
    first letter of each word while lowercasing the rest. A "word boundary"
    is defined as the position following a space, hyphen, period, apostrophe,
    or opening parenthesis.

Parameters:
    @text   VARCHAR(MAX) - The input string to convert.

Returns:
    VARCHAR(MAX) - The proper-cased string. Returns NULL if @text is NULL.

Example Usage:
    SELECT dbo.fn_ProperCase('my name is mohamed');   -- 'My Name Is Mohamed'
    SELECT dbo.fn_ProperCase('hello world');          -- 'Hello World'
    SELECT dbo.fn_ProperCase('o''brien-smith');       -- 'O'Brien-Smith'

Notes:
    - This function performs a character-by-character loop, so performance
      may degrade on very large strings or when applied across large result
      sets. For bulk/batch use, consider a set-based alternative.
===============================================================================
*/

CREATE FUNCTION dbo.fn_ProperCase (@text VARCHAR(MAX))
RETURNS VARCHAR(MAX)
AS
BEGIN
    IF @text IS NULL
        RETURN NULL;

    DECLARE @result   VARCHAR(MAX) = '';
    DECLARE @i        INT = 1;
    DECLARE @char     CHAR(1);
    DECLARE @prevChar CHAR(1) = ' ';

    SET @text = LOWER(@text);

    WHILE @i <= LEN(@text)
    BEGIN
        SET @char = SUBSTRING(@text, @i, 1);

        IF @prevChar IN (' ', '-', '.', '''', '(')
            SET @result = @result + UPPER(@char);
        ELSE
            SET @result = @result + @char;

        SET @prevChar = @char;
        SET @i = @i + 1;
    END

    RETURN @result;
END;
GO

-- ======================================================
-- Test cases
-- ======================================================
SELECT dbo.fn_ProperCase('my name is mohamed');  -- 'My Name Is Mohamed'
SELECT dbo.fn_ProperCase('hello world');         -- 'Hello World'
GO