-- =========================================================
--  Helper functions de seguridad para políticas en Supabase
-- =========================================================
--  Nota:  Todas estas funciones se crean con SECURITY DEFINER
--  para que puedan ser invocadas dentro de Row‑Level Policies
--  aún cuando el rol de ejecución (authenticated/anon) no
--  tenga privilegios directos sobre las tablas verificadas.
--  Devuelven BOOLEAN y lanzan una excepción cuando la condición
--  de seguridad no se cumple, de modo que la transacción se
--  cancela con un error explícito de autorización.

CREATE OR REPLACE FUNCTION is_role(p_user_id uuid, p_role_id int)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.user_role
    WHERE id = p_user_id
      AND value = p_role_id
  ) THEN
    RETURN true;
  END IF;
  RETURN false;
END;
$function$;

CREATE OR REPLACE FUNCTION is_firefighter()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  RETURN is_role(auth.uid(), 0);
END;
$function$;

CREATE OR REPLACE FUNCTION is_supervisor()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  RETURN is_role(auth.uid(), 1);
END;
$function$;

CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  RETURN is_role(auth.uid(), 2);
END;
$function$;

CREATE OR REPLACE FUNCTION only_firefighters()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  IF NOT is_firefighter() THEN
    RAISE EXCEPTION 'No autorizado: se requiere rol de bombero';
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION only_supervisors()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  IF NOT is_supervisor() THEN
    RAISE EXCEPTION 'No autorizado: se requiere rol de supervisor';
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION only_admins()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  IF NOT es_administrador() THEN
    RAISE EXCEPTION 'No autorizado: se requiere rol de administrador';
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION is_under_my_watch(p_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.user_hierarchy
    WHERE id = p_user_id
      AND watched_by = auth.uid()
  ) THEN
    RETURN true;
  END IF;
  RETURN false;
END;
$function$;

CREATE OR REPLACE FUNCTION is_watching_me(p_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.user_hierarchy
    WHERE id = auth.uid()
      AND watched_by = p_user_id
  ) THEN
    RETURN true;
  END IF;
  RETURN false;
END;
$function$;