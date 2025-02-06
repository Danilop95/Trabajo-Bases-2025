--------------------------------------------------------------------------------
-- 1) Eliminar Tablas sin Error ORA-00942
--------------------------------------------------------------------------------

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE ALDEANOS CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE CAMPAMENTOS CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE CASAS CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE PARTIDA CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE USUARIO CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE DATOS_CAMPAMENTOS CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE PARAMETROS CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

--------------------------------------------------------------------------------
-- 2) Creación de Tablas
--------------------------------------------------------------------------------

-- PARAMETROS (costes globales)
CREATE TABLE PARAMETROS (
  Id_Parametros       NUMBER PRIMARY KEY,
  Coste_Aldeanos      NUMBER NOT NULL,
  Coste_Casas         NUMBER NOT NULL,
  Capacidad_Por_Casa  NUMBER NOT NULL,
  Coste_Campamento    NUMBER NOT NULL
);

-- DATOS_CAMPAMENTOS (costes y producción por nivel y tipo)
CREATE TABLE DATOS_CAMPAMENTOS (
  Id_Datos_Campamentos     NUMBER PRIMARY KEY,
  Nivel                    NUMBER NOT NULL,
  Tipo                     VARCHAR2(50) NOT NULL, 
  Coste_Madera_Mejora      NUMBER NOT NULL,
  Coste_Ladrillo_Mejora    NUMBER NOT NULL,
  Coste_Oro_Mejora         NUMBER NOT NULL,
  Numero_Trabajadores_Al_100 NUMBER NOT NULL,
  Produccion               NUMBER NOT NULL
);

-- USUARIO (datos del jugador)
CREATE TABLE USUARIO (
  Id_Usuario   NUMBER PRIMARY KEY,
  Nombre       VARCHAR2(100) NOT NULL,
  Contraseña   VARCHAR2(100) NOT NULL
);

-- PARTIDA (recursos y relación a USUARIO)
CREATE TABLE PARTIDA (
  Id_Partida   NUMBER PRIMARY KEY,
  Madera       NUMBER NOT NULL,
  Ladrillo     NUMBER NOT NULL,
  Oro          NUMBER NOT NULL,
  Numero_Casas NUMBER NOT NULL,
  Id_Usuario   NUMBER UNIQUE,
  CONSTRAINT fk_partida_usuario
    FOREIGN KEY (Id_Usuario) REFERENCES USUARIO (Id_Usuario)
);

-- CASAS (cada casa construida en una partida)
CREATE TABLE CASAS (
  Id_Casa     NUMBER PRIMARY KEY,
  Id_Partida  NUMBER NOT NULL,
  CONSTRAINT fk_casas_partida
    FOREIGN KEY (Id_Partida) REFERENCES PARTIDA (Id_Partida)
);

-- CAMPAMENTOS (tipos: Madera, Piedra, Oro; nivel, trabajadores asignados, etc.)
CREATE TABLE CAMPAMENTOS (
  Id_Campamentos  NUMBER PRIMARY KEY,
  Tipo            VARCHAR2(50) NOT NULL,
  Nivel           NUMBER NOT NULL,
  N_Trabajadores  NUMBER NOT NULL,
  Id_Partida      NUMBER NOT NULL,
  CONSTRAINT fk_campamentos_partida
    FOREIGN KEY (Id_Partida) REFERENCES PARTIDA (Id_Partida)
);

-- ALDEANOS (estado y ubicación en casas o campamentos)
CREATE TABLE ALDEANOS (
  Id_Aldeanos     NUMBER PRIMARY KEY,
  Estado          VARCHAR2(50) NOT NULL,
  Id_Partida      NUMBER NOT NULL,
  Id_Casa         NUMBER,
  Id_Campamentos  NUMBER,
  CONSTRAINT fk_aldeanos_partida
    FOREIGN KEY (Id_Partida) REFERENCES PARTIDA (Id_Partida),
  CONSTRAINT fk_aldeanos_casas
    FOREIGN KEY (Id_Casa) REFERENCES CASAS(Id_Casa),
  CONSTRAINT fk_aldeanos_camp
    FOREIGN KEY (Id_Campamentos) REFERENCES CAMPAMENTOS(Id_Campamentos)
);

--------------------------------------------------------------------------------
-- 3) Inserción de Datos
--------------------------------------------------------------------------------

-- 3.1. Usuario "fonsi" (ID=1) con contraseña "lll"
INSERT INTO USUARIO (Id_Usuario, Nombre, Contraseña)
VALUES (1, 'fonsi', 'lll');

-- 3.2. Partida (ID=1) con recursos 0 y 1 casa, vinculada al usuario 1
INSERT INTO PARTIDA (Id_Partida, Madera, Ladrillo, Oro, Numero_Casas, Id_Usuario)
VALUES (1, 0, 0, 0, 1, 1);

-- 3.3. Datos de campamentos (ejemplo, niveles 1 a 5 para Madera, Piedra, Oro)
INSERT INTO DATOS_CAMPAMENTOS
  (Id_Datos_Campamentos, Nivel, Tipo, Coste_Madera_Mejora,
   Coste_Ladrillo_Mejora, Coste_Oro_Mejora, Numero_Trabajadores_Al_100, Produccion)
VALUES
  (1, 1, 'Madera', 100, 0, 0, 10, 50),
  (2, 1, 'Piedra', 100, 0, 0, 10, 50),
  (3, 1, 'Oro',    100, 0, 0, 10, 50),
  (4, 2, 'Madera', 200, 0, 0, 20, 100),
  (5, 2, 'Piedra', 200, 0, 0, 20, 100),
  (6, 2, 'Oro',    200, 0, 0, 20, 100),
  (7, 3, 'Madera', 400, 0, 0, 40, 200),
  (8, 3, 'Piedra', 400, 0, 0, 40, 200),
  (9, 3, 'Oro',    400, 0, 0, 40, 200),
  (10, 4, 'Madera', 500, 0, 0, 50, 250),
  (11, 4, 'Piedra', 500, 0, 0, 50, 250),
  (12, 4, 'Oro',    500, 0, 0, 50, 250),
  (13, 5, 'Madera', 600, 0, 0, 70, 270),
  (14, 5, 'Piedra', 600, 0, 0, 70, 270),
  (15, 5, 'Oro',    600, 0, 0, 70, 270);

-- 3.4. Parametros globales (ejemplo)
INSERT INTO PARAMETROS (Id_Parametros, Coste_Aldeanos, Coste_Casas, Capacidad_Por_Casa, Coste_Campamento)
VALUES (1, 50, 100, 5, 200);

-- 3.5. Casa (Id=1) para la Partida (Id=1)
INSERT INTO CASAS (Id_Casa, Id_Partida)
VALUES (1, 1);

-- 3.6. Campamento de Madera nivel 1 en la Partida 1 (sin trabajadores)
INSERT INTO CAMPAMENTOS (Id_Campamentos, Tipo, Nivel, N_Trabajadores, Id_Partida)
VALUES (1, 'Madera', 1, 0, 1);

-- 3.7. Un aldeano en estado "Descansando" en la misma partida
INSERT INTO ALDEANOS (Id_Aldeanos, Estado, Id_Partida, Id_Casa, Id_Campamentos)
VALUES (1, 'Descansando', 1, 1, NULL);

--------------------------------------------------------------------------------
-- 4) Procedimiento para Subir Nivel de Campamento de Madera
--------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE subir_nivel_campamento_madera (
    p_IdPartida NUMBER
)
AS
    v_Coste_Madera      NUMBER;
    v_Madera_Disponible NUMBER;
    v_Nivel_Actual      NUMBER;
BEGIN
    -- Obtener nivel actual del campamento 'Madera'
    SELECT Nivel
      INTO v_Nivel_Actual
      FROM CAMPAMENTOS
     WHERE Tipo = 'Madera'
       AND Id_Partida = p_IdPartida;

    -- Obtener coste de mejora según DATOS_CAMPAMENTOS
    SELECT Coste_Madera_Mejora
      INTO v_Coste_Madera
      FROM DATOS_CAMPAMENTOS
     WHERE Nivel = v_Nivel_Actual
       AND Tipo = 'Madera';

    -- Leer la madera disponible en la partida
    SELECT Madera
      INTO v_Madera_Disponible
      FROM PARTIDA
     WHERE Id_Partida = p_IdPartida;

    -- Verificar si hay suficiente madera
    IF v_Madera_Disponible >= v_Coste_Madera THEN
       -- Subir el nivel del campamento
       UPDATE CAMPAMENTOS
          SET Nivel = Nivel + 1
        WHERE Tipo = 'Madera'
          AND Id_Partida = p_IdPartida;

       -- Descontar la madera
       UPDATE PARTIDA
          SET Madera = Madera - v_Coste_Madera
        WHERE Id_Partida = p_IdPartida;

       DBMS_OUTPUT.PUT_LINE('Se ha subido el campamento de Madera. Nueva Madera: ' ||
                            (v_Madera_Disponible - v_Coste_Madera));
    ELSE
       DBMS_OUTPUT.PUT_LINE('No hay madera suficiente para mejorar el campamento de Madera.');
    END IF;
END;
/
CREATE OR REPLACE PROCEDURE subir_nivel_campamento_madera
AS
    v_Coste_Madera       NUMBER;
    v_Coste_Ladrillo     NUMBER;
    v_Madera_Disponible  NUMBER;
    v_Ladrillo_Disponible NUMBER;
    v_Nivel_Actual       NUMBER;
BEGIN
    -- 1) OBTENER EL NIVEL ACTUAL DEL CAMPAMENTO
    SELECT Nivel
      INTO v_Nivel_Actual
      FROM campamentos
     WHERE Tipo = 'Madera' 
       AND Id_Partida = 1;

    -- 2) OBTENER COSTES DE MEJORA SEGÚN DATOS_CAMPAMENTOS
    SELECT Coste_Madera_Mejora, Coste_Ladrillo_Mejora
      INTO v_Coste_Madera, v_Coste_Ladrillo
      FROM DATOS_CAMPAMENTOS
     WHERE Nivel = v_Nivel_Actual
       AND Tipo  = 'Madera';

    -- 3) OBTENER LA MADERA Y LADRILLO DISPONIBLES EN LA PARTIDA
    SELECT Madera, Ladrillo
      INTO v_Madera_Disponible, v_Ladrillo_Disponible
      FROM PARTIDA
     WHERE Id_Partida = 1;

    -- 4) VERIFICAR SI HAY RECURSOS SUFICIENTES
    IF v_Ladrillo_Disponible >= v_Coste_Ladrillo 
       AND v_Madera_Disponible >= v_Coste_Madera
    THEN
       -- a) SUBIR EL NIVEL DEL CAMPAMENTO
       UPDATE campamentos
          SET Nivel = Nivel + 1
        WHERE Tipo = 'Madera'
          AND Id_Partida = 1;

       -- b) DESCONTAR LOS RECURSOS AL JUGADOR
       UPDATE PARTIDA
          SET Madera   = Madera   - v_Coste_Madera,
              Ladrillo = Ladrillo - v_Coste_Ladrillo
        WHERE Id_Partida = 1;

       -- Opcional: salida de consola en Oracle (DBMS_OUTPUT)
       DBMS_OUTPUT.PUT_LINE('Campamento Madera subido de nivel correctamente.');
       DBMS_OUTPUT.PUT_LINE('Madera ahora = ' || (v_Madera_Disponible - v_Coste_Madera));
       DBMS_OUTPUT.PUT_LINE('Ladrillo ahora = ' || (v_Ladrillo_Disponible - v_Coste_Ladrillo));

    ELSE
       DBMS_OUTPUT.PUT_LINE('No hay suficientes recursos para mejorar el campamento de Madera.');
    END IF;
END;
/
--------------------------------------------------------------------------------
-- 1) Eliminar Tablas sin Error ORA-00942
--------------------------------------------------------------------------------

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE ALDEANOS CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE CAMPAMENTOS CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE CASAS CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE PARTIDA CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE USUARIO CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE DATOS_CAMPAMENTOS CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE; END IF;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE PARAMETROS CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

--------------------------------------------------------------------------------
-- 2) Creación de Tablas
--------------------------------------------------------------------------------

-- PARAMETROS (costes globales)
CREATE TABLE PARAMETROS (
  Id_Parametros       NUMBER PRIMARY KEY,
  Coste_Aldeanos      NUMBER NOT NULL,
  Coste_Casas         NUMBER NOT NULL,
  Capacidad_Por_Casa  NUMBER NOT NULL,
  Coste_Campamento    NUMBER NOT NULL
);

-- DATOS_CAMPAMENTOS (costes y producción por nivel y tipo)
CREATE TABLE DATOS_CAMPAMENTOS (
  Id_Datos_Campamentos     NUMBER PRIMARY KEY,
  Nivel                    NUMBER NOT NULL,
  Tipo                     VARCHAR2(50) NOT NULL, 
  Coste_Madera_Mejora      NUMBER NOT NULL,
  Coste_Ladrillo_Mejora    NUMBER NOT NULL,
  Coste_Oro_Mejora         NUMBER NOT NULL,
  Numero_Trabajadores_Al_100 NUMBER NOT NULL,
  Produccion               NUMBER NOT NULL
);

-- USUARIO (datos del jugador)
CREATE TABLE USUARIO (
  Id_Usuario   NUMBER PRIMARY KEY,
  Nombre       VARCHAR2(100) NOT NULL,
  Contraseña   VARCHAR2(100) NOT NULL
);

-- PARTIDA (recursos y relación a USUARIO)
CREATE TABLE PARTIDA (
  Id_Partida   NUMBER PRIMARY KEY,
  Madera       NUMBER NOT NULL,
  Ladrillo     NUMBER NOT NULL,
  Oro          NUMBER NOT NULL,
  Numero_Casas NUMBER NOT NULL,
  Id_Usuario   NUMBER UNIQUE,
  CONSTRAINT fk_partida_usuario
    FOREIGN KEY (Id_Usuario) REFERENCES USUARIO (Id_Usuario)
);

-- CASAS (cada casa construida en una partida)
CREATE TABLE CASAS (
  Id_Casa     NUMBER PRIMARY KEY,
  Id_Partida  NUMBER NOT NULL,
  CONSTRAINT fk_casas_partida
    FOREIGN KEY (Id_Partida) REFERENCES PARTIDA (Id_Partida)
);

-- CAMPAMENTOS (tipos: Madera, Piedra, Oro; nivel, trabajadores asignados, etc.)
CREATE TABLE CAMPAMENTOS (
  Id_Campamentos  NUMBER PRIMARY KEY,
  Tipo            VARCHAR2(50) NOT NULL,
  Nivel           NUMBER NOT NULL,
  N_Trabajadores  NUMBER NOT NULL,
  Id_Partida      NUMBER NOT NULL,
  CONSTRAINT fk_campamentos_partida
    FOREIGN KEY (Id_Partida) REFERENCES PARTIDA (Id_Partida)
);

-- ALDEANOS (estado y ubicación en casas o campamentos)
CREATE TABLE ALDEANOS (
  Id_Aldeanos     NUMBER PRIMARY KEY,
  Estado          VARCHAR2(50) NOT NULL,
  Id_Partida      NUMBER NOT NULL,
  Id_Casa         NUMBER,
  Id_Campamentos  NUMBER,
  CONSTRAINT fk_aldeanos_partida
    FOREIGN KEY (Id_Partida) REFERENCES PARTIDA(Id_Partida),
  CONSTRAINT fk_aldeanos_casas
    FOREIGN KEY (Id_Casa) REFERENCES CASAS(Id_Casa),
  CONSTRAINT fk_aldeanos_camp
    FOREIGN KEY (Id_Campamentos) REFERENCES CAMPAMENTOS(Id_Campamentos)
);

--------------------------------------------------------------------------------
-- 3) Inserción de Datos
--------------------------------------------------------------------------------

-- 3.1. Usuario "fonsi" (ID=1) con contraseña "lll"
INSERT INTO USUARIO (Id_Usuario, Nombre, Contraseña)
VALUES (1, 'fonsi', 'lll');

-- 3.2. Partida (ID=1) con recursos 0 y 1 casa, vinculada al usuario 1
INSERT INTO PARTIDA (Id_Partida, Madera, Ladrillo, Oro, Numero_Casas, Id_Usuario)
VALUES (1, 0, 0, 0, 1, 1);

-- 3.3. Datos de campamentos (ejemplo, niveles 1 a 5 para Madera, Piedra, Oro)
INSERT INTO DATOS_CAMPAMENTOS
  (Id_Datos_Campamentos, Nivel, Tipo, Coste_Madera_Mejora,
   Coste_Ladrillo_Mejora, Coste_Oro_Mejora, Numero_Trabajadores_Al_100, Produccion)
VALUES
  (1, 1, 'Madera', 100,  0,   0, 10, 50),
  (2, 1, 'Piedra', 100,  0,   0, 10, 50),
  (3, 1, 'Oro',    100,  0,   0, 10, 50),
  (4, 2, 'Madera', 200,  0,   0, 20, 100),
  (5, 2, 'Piedra', 200,  0,   0, 20, 100),
  (6, 2, 'Oro',    200,  0,   0, 20, 100),
  (7, 3, 'Madera', 400,  0,   0, 40, 200),
  (8, 3, 'Piedra', 400,  0,   0, 40, 200),
  (9, 3, 'Oro',    400,  0,   0, 40, 200),
  (10,4, 'Madera', 500,  0,   0, 50, 250),
  (11,4, 'Piedra', 500,  0,   0, 50, 250),
  (12,4, 'Oro',    500,  0,   0, 50, 250),
  (13,5, 'Madera', 600,  0,   0, 70, 270),
  (14,5, 'Piedra', 600,  0,   0, 70, 270),
  (15,5, 'Oro',    600,  0,   0, 70, 270);

-- 3.4. Parametros globales (ejemplo)
INSERT INTO PARAMETROS (Id_Parametros, Coste_Aldeanos, Coste_Casas, Capacidad_Por_Casa, Coste_Campamento)
VALUES (1, 50, 100, 5, 200);

-- 3.5. Casa (Id=1) para la Partida (Id=1)
INSERT INTO CASAS (Id_Casa, Id_Partida)
VALUES (1, 1);

-- 3.6. Campamento de Madera nivel 1 en la Partida 1 (sin trabajadores)
INSERT INTO CAMPAMENTOS (Id_Campamentos, Tipo, Nivel, N_Trabajadores, Id_Partida)
VALUES (1, 'Madera', 1, 0, 1);

-- 3.7. Un aldeano en estado "Descansando" en la misma partida
INSERT INTO ALDEANOS (Id_Aldeanos, Estado, Id_Partida, Id_Casa, Id_Campamentos)
VALUES (1, 'Descansando', 1, 1, NULL);

--------------------------------------------------------------------------------
-- 4) Procedimiento Único para Subir Nivel (Madera) Descontando Madera y Ladrillo
--------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE subir_nivel_campamento_madera
AS
    v_Coste_Madera       NUMBER;
    v_Coste_Ladrillo     NUMBER;
    v_Madera_Disponible  NUMBER;
    v_Ladrillo_Disponible NUMBER;
    v_Nivel_Actual       NUMBER;
BEGIN
    -- 1) Obtener el nivel actual
    SELECT Nivel
      INTO v_Nivel_Actual
      FROM CAMPAMENTOS
     WHERE Tipo = 'Madera'
       AND Id_Partida = 1;

    -- 2) Obtener costes de mejora
    SELECT Coste_Madera_Mejora, Coste_Ladrillo_Mejora
      INTO v_Coste_Madera, v_Coste_Ladrillo
      FROM DATOS_CAMPAMENTOS
     WHERE Nivel = v_Nivel_Actual
       AND Tipo = 'Madera';

    -- 3) Obtener Madera y Ladrillo disponibles
    SELECT Madera, Ladrillo
      INTO v_Madera_Disponible, v_Ladrillo_Disponible
      FROM PARTIDA
     WHERE Id_Partida = 1;

    -- 4) Comprobar recursos
    IF (v_Madera_Disponible  >= v_Coste_Madera)
       AND (v_Ladrillo_Disponible >= v_Coste_Ladrillo)
    THEN
       -- Subir nivel campamento
       UPDATE CAMPAMENTOS
         SET Nivel = Nivel + 1
       WHERE Tipo = 'Madera'
         AND Id_Partida = 1;

       -- Descontar recursos
       UPDATE PARTIDA
         SET Madera   = Madera   - v_Coste_Madera,
             Ladrillo = Ladrillo - v_Coste_Ladrillo
       WHERE Id_Partida = 1;

       DBMS_OUTPUT.PUT_LINE('Campamento Madera subido de nivel correctamente.');
       DBMS_OUTPUT.PUT_LINE('Madera actual = ' || (v_Madera_Disponible - v_Coste_Madera));
       DBMS_OUTPUT.PUT_LINE('Ladrillo actual = ' || (v_Ladrillo_Disponible - v_Coste_Ladrillo));
    ELSE
       DBMS_OUTPUT.PUT_LINE('No hay suficientes recursos para mejorar Madera.');
    END IF;
END;
/
