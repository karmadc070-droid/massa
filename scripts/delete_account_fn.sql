-- 로그인 사용자가 앱 안에서 자기 계정을 직접 삭제하도록 하는 함수 (Apple 5.1.1(v) 요건)

-- 1) 진단: auth.users(id)를 참조하는 FK와 삭제 규칙 확인
SELECT tc.table_schema || '.' || tc.table_name AS child_table,
       kcu.column_name,
       rc.delete_rule
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu
    ON kcu.constraint_name = tc.constraint_name
  JOIN information_schema.referential_constraints rc
    ON rc.constraint_name = tc.constraint_name
  JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
 WHERE tc.constraint_type = 'FOREIGN KEY'
   AND ccu.table_schema = 'auth' AND ccu.table_name = 'users'
 ORDER BY 1;

-- 2) 함수 생성: 자기 자신의 auth 계정을 삭제한다. 하위 데이터는 FK 규칙을 따른다.
CREATE OR REPLACE FUNCTION public.delete_my_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $fn$
DECLARE
  uid uuid := auth.uid();
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;
  DELETE FROM auth.users WHERE id = uid;
END;
$fn$;

REVOKE ALL ON FUNCTION public.delete_my_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_my_account() TO authenticated;

SELECT 'DELETE_FN_OK' AS result;
