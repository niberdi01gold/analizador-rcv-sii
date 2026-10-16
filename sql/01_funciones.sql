-- =====================================================================
-- 01 · Funciones de apoyo
-- Validación de RUT (módulo 11) y conversiones que no se caen con datos malos.
-- Van primero porque las tablas las usan en sus reglas CHECK.
-- =====================================================================

-- Dígito verificador de un RUT a partir de su número (Lección 2)
CREATE FUNCTION dv_rut(cuerpo bigint)
RETURNS text
LANGUAGE plpgsql AS $$
DECLARE
    n              bigint := cuerpo;
    suma           int := 0;
    multiplicador  int := 2;
    resultado      int;
BEGIN
    WHILE n > 0 LOOP
        suma := suma + (n % 10) * multiplicador;
        n := n / 10;
        multiplicador := multiplicador + 1;
        IF multiplicador > 7 THEN
            multiplicador := 2;
        END IF;
    END LOOP;

    resultado := 11 - (suma % 11);

    IF resultado = 11 THEN
        RETURN '0';
    ELSIF resultado = 10 THEN
        RETURN 'K';
    ELSE
        RETURN resultado::text;
    END IF;
END;
$$;

-- ¿El RUT completo (12345678-5) es válido? (Lección 2)
CREATE FUNCTION rut_valido(rut text)
RETURNS boolean
LANGUAGE sql AS $$
    SELECT CASE
        WHEN upper(rut) ~ '^[0-9]{1,8}-[0-9K]$'
            THEN dv_rut(split_part(rut, '-', 1)::bigint) = split_part(upper(rut), '-', 2)
        ELSE false
    END;
$$;

-- Texto a número; NULL si no se puede (Lección 4)
CREATE FUNCTION a_numero(texto text) RETURNS bigint LANGUAGE plpgsql AS $$
BEGIN
    RETURN texto::bigint;
EXCEPTION WHEN others THEN
    RETURN NULL;
END;
$$;

-- Texto dd/mm/aaaa a fecha; NULL si la fecha no existe (Lección 4)
CREATE FUNCTION a_fecha(texto text) RETURNS date LANGUAGE plpgsql AS $$
BEGIN
    RETURN to_date(texto, 'DD/MM/YYYY');
EXCEPTION WHEN others THEN
    RETURN NULL;
END;
$$;
