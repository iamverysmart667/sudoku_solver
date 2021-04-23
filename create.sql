create type CELL is varray(2) of NUMBER(0)
/

create type SUDOKU_ROW as table of NUMBER(1)
/

create type SUDOKU_TABLE as table of SUDOKU_ROW
/

create table SUDOKU
(
	COL1 NUMBER,
	COL2 NUMBER,
	COL3 NUMBER,
	COL4 NUMBER,
	COL5 NUMBER,
	COL6 NUMBER,
	COL7 NUMBER,
	COL8 NUMBER,
	COL9 NUMBER,
	ID NUMBER not null
		primary key
)
/

create or replace trigger VALID_CELL
	before update
	on SUDOKU
	for each row
begin
    if :new.col1 < 0 or :new.col1 > 9 or
       :new.col2 < 0 or :new.col2 > 9 or
       :new.col3 < 0 or :new.col3 > 9 or
       :new.col4 < 0 or :new.col4 > 9 or
       :new.col5 < 0 or :new.col5 > 9 or
       :new.col6 < 0 or :new.col6 > 9 or
       :new.col7 < 0 or :new.col7 > 9 or
       :new.col8 < 0 or :new.col8 > 9 or
       :new.col9 < 0 or :new.col9 > 9 then
        raise_application_error(-20123, 'Invalid cell format');
    end if;
end;
/

create or replace package array2d as
    procedure print(a in sudoku_table);
    procedure save(a in sudoku_table);
end;
/

create or replace procedure print(s varchar default '') is begin
    dbms_output.put(s);
end;
/

create or replace function find_empty_cell(a in sudoku_table)
    return cell is
begin
    for i in 1..9 loop
        for j in 1..9 loop
            if a(i)(j) = 0 then
                return cell(i, j);
            end if;
        end loop;
    end loop;
    return cell(-1, -1);
end;
/

create or replace function check_row(a in sudoku_table, row number, val number)
return boolean is
begin
    for i in 1..9 loop
        if a(row)(i) = val then
            return false;
        end if;
    end loop;
    return true;
end;
/

create or replace function check_col(a in sudoku_table, col number, val number)
    return boolean is
begin
    for i in 1..9 loop
        if a(i)(col) = val then
            return false;
        end if;
    end loop;
    return true;
end;
/

create or replace function check_square(a in sudoku_table, row number, col number, val number)
    return boolean is
    ans boolean := true;
begin
    for i in row..row+2 loop
        for j in col..col+2 loop ans := ans and (a(i)(j) <> val); end loop;
    end loop;
    return ans;
end;
/

create or replace function possible(a in sudoku_table, row number, col number, val number)
    return boolean is
    s_row number := (row - 1) - mod(row - 1, 3);
    s_col number := (col - 1) - mod(col - 1, 3);
begin
    return ((check_row(a, row, val) and
           check_col(a, col, val)) and
           check_square(a, s_row + 1, s_col + 1, val));
end;
/

create or replace function solve(a in out sudoku_table)
    return boolean is
    c cell;
begin
    c := find_empty_cell(a);
--     print('CELL: ' || c(1) || ', ' || c(2));
    if c(1) = -1 and c(2) = -1 then
        return true;
    end if;

    for val in 1..9 loop
        if possible(a, c(1), c(2), val) then
            a(c(1))(c(2)) := val;
            if solve(a) then return true; end if;
            a(c(1))(c(2)) := 0;
        end if;
    end loop;

    return false;
end;
/

create or replace procedure put(row NUMBER, col NUMBER, val NUMBER) is
    r varchar(1) := to_char(row);
    c varchar(4) := 'col' || to_char(col);
begin
    execute immediate 'update sudoku set ' || c || ' = ' || val || ' where id = ' || r;
    commit;
end;
/

create or replace package body array2d as
    procedure print(a in sudoku_table) is begin
        for i in 1..9 loop
            for j in 1..9 loop
                dbms_output.put(a(i)(j) || ' ');
            end loop;
            dbms_output.put_line('');
        end loop;
        dbms_output.put_line('');
    end;

    procedure save(a in sudoku_table) is begin
        for i in 1..9 loop
            for j in 1..9 loop
                put(i, j, a(i)(j));
            end loop;
        end loop;
    end;
end;
/

create or replace function get(row NUMBER, col NUMBER)
return number is
    r varchar(1) := to_char(row);
    c varchar(4) := 'col' || to_char(col);
    v number;
begin
    execute immediate 'select ' || c || ' from sudoku where id = ' || r into v;
    return v;
end;
/

create or replace procedure println(s varchar default '') is begin
    dbms_output.put_line(s);
end;
/

create or replace procedure main is
    a sudoku_table;
    c boolean;
begin
    a := new sudoku_table(
        sudoku_row(1, 0, 0, 0, 0, 0, 0, 0, 0),
        sudoku_row(0, 2, 0, 0, 0, 0, 0, 0, 0),
        sudoku_row(0, 0, 3, 0, 0, 0, 0, 0, 0),
        sudoku_row(0, 0, 0, 0, 0, 0, 0, 0, 0),
        sudoku_row(0, 0, 0, 0, 0, 0, 0, 0, 0),
        sudoku_row(0, 0, 0, 0, 0, 0, 0, 0, 0),
        sudoku_row(0, 0, 0, 0, 0, 0, 0, 0, 0),
        sudoku_row(0, 0, 0, 0, 0, 0, 0, 0, 0),
        sudoku_row(0, 0, 0, 0, 0, 0, 0, 0, 0)
    );
    for i in 1..9 loop
        for j in 1..9 loop
            a(i)(j) := get(i, j);
        end loop;
    end loop;
    c := solve(a);
    array2d.print(a);
    array2d.save(a);
    if c then
        println('YES');
    else
        println('NO');
    end if;
end;
/

create or replace procedure print_board is
    cursor c_board is select * from sudoku;
begin
    for row in c_board loop
        println(
            row.col1 || row.col2 || row.col3 ||
               row.col4 || row.col5 || row.col6 ||
               row.col7 || row.col8 || row.col9
        );
    end loop;
end;
/


