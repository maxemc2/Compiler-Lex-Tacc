{* Sigma.sp
 *
 * Compute sum = 1 + 2 + ... + n
 *}
program test
  -- <declare zero or more variable and constant declarations> --
  declare 
    x: integer;
    y: integer;
  -- <zero or more procedure declarations> --
  procedure computeSigma return integer
    -- constant and variable declarations
    declare
      n: constant := 10;
      sum: integer;
      index: integer;
    -- main statements
    begin
      index := 0;
      sum := 0;
      while (index <= n) loop
        begin
          sum := sum + index;
          index := index + 1;
        end;
      end loop;
      return sum;
    end;
  end computeSigma;
  procedure multiply (a: integer; b: float) return float
    -- constant and variable declarations
    declare
      i: integer;
      c: float := 1;
    -- main statements
    begin
      for (i in 1 .. 5) loop
          c := c * b;
      end loop;
      return c;
    end;
  end multiply;
  -- <zero or more statements> --
  begin
    x := computeSigma + multiply(1, 12.5);
    print x;
  end
end test
