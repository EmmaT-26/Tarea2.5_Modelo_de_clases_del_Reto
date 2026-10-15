-- =========================================
-- CREAR LA BASE DE DATOS
-- =========================================

CREATE DATABASE IF NOT EXISTS ParqueAmbiental;
USE ParqueAmbiental;

-- =========================================
-- 1. PARQUE
-- =========================================

CREATE TABLE Parque (
    id_parque INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    calle VARCHAR(100) NOT NULL,
    numero VARCHAR(10) NOT NULL,
    colonia VARCHAR(100) NOT NULL
);

-- =========================================
-- 2. ZONA
-- =========================================

CREATE TABLE Zona (
    id_parque INT NOT NULL,
    numero_de_zona INT NOT NULL,
    tipo VARCHAR(30) NOT NULL,

    PRIMARY KEY (id_parque, numero_de_zona),

    FOREIGN KEY (id_parque)
        REFERENCES Parque(id_parque),

    CHECK (tipo IN ('juegos', 'area verde', 'cancha'))
);

-- =========================================
-- 3. SENSOR
-- Se incorporan aquí los límites de medición
-- =========================================

CREATE TABLE Sensor (
    id_sensor INT PRIMARY KEY,
    id_parque INT NOT NULL,
    numero_de_zona INT NOT NULL,
    fecha_de_instalacion DATE NOT NULL,
    variable VARCHAR(50) NOT NULL,
    unidad VARCHAR(20) NOT NULL,
    minimo DECIMAL(10,2) NOT NULL,
    maximo DECIMAL(10,2) NOT NULL,

    FOREIGN KEY (id_parque, numero_de_zona)
        REFERENCES Zona(id_parque, numero_de_zona),

    CHECK (minimo <= maximo),

    CHECK (
        (variable = 'temperatura'
            AND unidad = '°C'
            AND minimo = 0 AND maximo = 35)
        OR
        (variable = 'humedad'
            AND unidad = '%'
            AND minimo = 0 AND maximo = 100)
        OR
        (variable = 'rayos_uv'
            AND unidad = 'UV'
            AND minimo = 0 AND maximo = 15)
        OR
        (variable = 'contaminacion_aire'
            AND unidad = 'µg/m³'
            AND minimo = 0 AND maximo = 500)
        OR
        (variable = 'movimiento'
            AND unidad = 'booleano'
            AND minimo = 0 AND maximo = 1)
        OR
        (variable = 'ruido'
            AND unidad = 'dBA'
            AND minimo = 25 AND maximo = 90)
    )
);

-- =========================================
-- 4. LECTURA
-- =========================================

CREATE TABLE Lectura (
    numero_de_lectura INT PRIMARY KEY,
    id_sensor INT NOT NULL,
    fecha DATE NOT NULL,
    hora TIME NOT NULL,
    valor DECIMAL(10,2) NOT NULL,

    FOREIGN KEY (id_sensor)
        REFERENCES Sensor(id_sensor)
);

-- =========================================
-- 5. ALERTA
-- Una lectura puede generar como máximo
-- una alerta
-- =========================================

CREATE TABLE Alerta (
    codigo INT PRIMARY KEY,
    numero_de_lectura INT NOT NULL UNIQUE,
    nivel VARCHAR(30) NOT NULL,
    mensaje VARCHAR(255) NOT NULL,

    FOREIGN KEY (numero_de_lectura)
        REFERENCES Lectura(numero_de_lectura)
);

-- =========================================
-- 6. VISITANTE
-- =========================================

CREATE TABLE Visitante (
    correo VARCHAR(150) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    fecha_de_registro DATE NOT NULL
);

-- =========================================
-- 7. ENVIOALERTA
-- Tabla intermedia de Alerta y Visitante
-- =========================================

CREATE TABLE EnvioAlerta (
    codigo_alerta INT NOT NULL,
    correo VARCHAR(150) NOT NULL,
    leido BOOLEAN NOT NULL DEFAULT FALSE,

    PRIMARY KEY (codigo_alerta, correo),

    FOREIGN KEY (codigo_alerta)
        REFERENCES Alerta(codigo),

    FOREIGN KEY (correo)
        REFERENCES Visitante(correo)
);

-- =========================================
-- VALIDAR LOS VALORES DE LAS LECTURAS
-- =========================================

DELIMITER //

CREATE TRIGGER validar_lectura_insert
BEFORE INSERT ON Lectura
FOR EACH ROW
BEGIN
    DECLARE v_min DECIMAL(10,2);
    DECLARE v_max DECIMAL(10,2);
    DECLARE v_variable VARCHAR(50);

    SELECT minimo, maximo, variable
    INTO v_min, v_max, v_variable
    FROM Sensor
    WHERE id_sensor = NEW.id_sensor;

    IF NEW.valor < v_min OR NEW.valor > v_max THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'La lectura esta fuera del rango permitido';
    END IF;

    IF v_variable = 'movimiento'
       AND NEW.valor NOT IN (0, 1) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'Movimiento solo acepta 0 o 1';
    END IF;
END//

CREATE TRIGGER validar_lectura_update
BEFORE UPDATE ON Lectura
FOR EACH ROW
BEGIN
    DECLARE v_min DECIMAL(10,2);
    DECLARE v_max DECIMAL(10,2);
    DECLARE v_variable VARCHAR(50);

    SELECT minimo, maximo, variable
    INTO v_min, v_max, v_variable
    FROM Sensor
    WHERE id_sensor = NEW.id_sensor;

    IF NEW.valor < v_min OR NEW.valor > v_max THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'La lectura esta fuera del rango permitido';
    END IF;

    IF v_variable = 'movimiento'
       AND NEW.valor NOT IN (0, 1) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'Movimiento solo acepta 0 o 1';
    END IF;
END//

DELIMITER ;

-- =========================================
-- AGREGAR DATOS DE PRUEBA A LA BASE
-- =========================================

-- 1. Parques
INSERT INTO Parque
(id_parque, nombre, calle, numero, colonia)
VALUES
(1, 'Parque Central', 'Reforma', '120', 'Centro'),
(2, 'Parque del Sol', 'Juarez', '45', 'La Paz');

-- 2. Zonas de cada parque
INSERT INTO Zona
(id_parque, numero_de_zona, tipo)
VALUES
(1, 1, 'area verde'),
(1, 2, 'juegos'),
(1, 3, 'cancha'),
(2, 1, 'area verde');

-- 3. Sensores
INSERT INTO Sensor
(id_sensor, id_parque, numero_de_zona, fecha_de_instalacion,
 variable, unidad, minimo, maximo)
VALUES
(101, 1, 1, '2026-09-01', 'temperatura', '°C', 0, 35),
(102, 1, 1, '2026-09-01', 'humedad', '%', 0, 100),
(103, 1, 1, '2026-09-02', 'rayos_uv', 'UV', 0, 15),
(104, 1, 2, '2026-09-03', 'contaminacion_aire', 'µg/m³', 0, 500),
(105, 1, 2, '2026-09-03', 'movimiento', 'booleano', 0, 1),
(106, 1, 3, '2026-09-04', 'ruido', 'dBA', 25, 90),
(107, 2, 1, '2026-09-05', 'temperatura', '°C', 0, 35),
(108, 2, 1, '2026-09-05', 'rayos_uv', 'UV', 0, 15);

-- 4. Mediciones simuladas: 24 lecturas
INSERT INTO Lectura
(numero_de_lectura, id_sensor, fecha, hora, valor)
VALUES
(1001, 101, '2026-10-10', '07:00:00', 22.00),
(1002, 101, '2026-10-10', '09:00:00', 28.50),
(1003, 101, '2026-10-10', '12:00:00', 34.00),
(1004, 101, '2026-10-10', '14:00:00', 35.00),
(1005, 101, '2026-10-11', '07:00:00', 21.00),
(1006, 101, '2026-10-11', '12:00:00', 30.00),

(1007, 102, '2026-10-10', '07:00:00', 55.00),
(1008, 102, '2026-10-10', '12:00:00', 82.00),
(1009, 102, '2026-10-11', '07:00:00', 60.00),

(1010, 103, '2026-10-10', '07:00:00', 2.00),
(1011, 103, '2026-10-10', '12:00:00', 13.00),
(1012, 103, '2026-10-10', '16:00:00', 5.00),
(1013, 103, '2026-10-11', '07:00:00', 1.00),

(1014, 104, '2026-10-10', '07:00:00', 45.00),
(1015, 104, '2026-10-10', '12:00:00', 180.00),
(1016, 104, '2026-10-10', '14:00:00', 320.00),
(1017, 104, '2026-10-11', '08:00:00', 40.00),

(1018, 105, '2026-10-10', '07:00:00', 0.00),
(1019, 105, '2026-10-10', '12:00:00', 1.00),
(1020, 105, '2026-10-10', '14:00:00', 1.00),

(1021, 106, '2026-10-10', '07:00:00', 35.00),
(1022, 106, '2026-10-10', '12:00:00', 65.00),
(1023, 106, '2026-10-10', '14:00:00', 78.00),

(1024, 107, '2026-10-10', '08:00:00', 26.00);

-- 5. Alertas asociadas a mediciones
INSERT INTO Alerta
(codigo, numero_de_lectura, nivel, mensaje)
VALUES
(201, 1004, 'Alto', 'Temperatura cercana al limite maximo'),
(202, 1008, 'Alto', 'Humedad elevada'),
(203, 1011, 'Alto', 'Intensidad de rayos UV elevada'),
(204, 1016, 'Alto', 'Contaminacion del aire elevada');

-- 6. Visitantes registrados
INSERT INTO Visitante
(correo, nombre, fecha_de_registro)
VALUES
('ana@example.com', 'Ana Lopez', '2026-10-01'),
('luis@example.com', 'Luis Perez', '2026-10-02'),
('maria@example.com', 'Maria Garcia', '2026-10-03');

-- 7. Envío de alertas a visitantes
INSERT INTO EnvioAlerta
(codigo_alerta, correo, leido)
VALUES
(201, 'ana@example.com', FALSE),
(202, 'luis@example.com', FALSE),
(203, 'ana@example.com', TRUE),
(204, 'maria@example.com', FALSE);

-- =========================================
-- CONSULTAS
-- =========================================

-- Identificación de condiciones ambientales 
SELECT
    p.nombre AS parque,
    s.variable,
    l.fecha,
    l.hora,
    l.valor,
    s.unidad
FROM Lectura AS l
INNER JOIN Sensor AS s
    ON l.id_sensor = s.id_sensor
INNER JOIN Parque AS p
    ON s.id_parque = p.id_parque
WHERE
    (s.variable = 'temperatura' AND l.valor >= 30)
    OR (s.variable = 'humedad' AND l.valor >= 80)
    OR (s.variable = 'rayos_uv' AND l.valor >= 8)
    OR (s.variable = 'contaminacion_aire' AND l.valor >= 150)
    OR (s.variable = 'ruido' AND l.valor >= 70)
ORDER BY l.fecha, l.hora;

-- Calculo de temparatura promedio por día y parque
SELECT
    p.nombre AS parque,
    l.fecha,
    AVG(l.valor) AS temperatura_promedio
FROM Lectura AS l
INNER JOIN Sensor AS s
    ON l.id_sensor = s.id_sensor
INNER JOIN Parque AS p
    ON s.id_parque = p.id_parque
WHERE s.variable = 'temperatura'
GROUP BY p.nombre, l.fecha
ORDER BY l.fecha, p.nombre;

-- Consultar alertas enviadas a los visitantes
SELECT
    a.codigo AS codigo_alerta,
    a.nivel,
    a.mensaje,
    v.nombre AS visitante,
    v.correo,
    e.leido
FROM EnvioAlerta AS e
INNER JOIN Alerta AS a
    ON e.codigo_alerta = a.codigo
INNER JOIN Visitante AS v
    ON e.correo = v.correo
ORDER BY a.codigo, v.nombre;

-- Contar mediciones registradas por variable
SELECT
    s.variable,
    COUNT(l.numero_de_lectura) AS total_mediciones
FROM Sensor AS s
LEFT JOIN Lectura AS l
    ON s.id_sensor = l.id_sensor
GROUP BY s.variable
ORDER BY total_mediciones DESC;

-- Consulta de temperaturas máximas registradas
SELECT
    p.nombre AS parque,
    MAX(l.valor) AS temperatura_maxima,
    s.unidad
FROM Lectura AS l
INNER JOIN Sensor AS s
    ON l.id_sensor = s.id_sensor
INNER JOIN Parque AS p
    ON s.id_parque = p.id_parque
WHERE s.variable = 'temperatura'
GROUP BY p.nombre, s.unidad
ORDER BY temperatura_maxima DESC;