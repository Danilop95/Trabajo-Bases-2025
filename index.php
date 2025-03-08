<?php
/**************************************************************
 * Ejemplo de aplicación "Clash of Bases" en un solo archivo
 * Requiere:
 *    - PHP 7+ (o 8+)
 *    - MySQL 5.7+ (o 8+)
 *    - Extensión PDO activada en PHP
 * Ajusta user/pass de MySQL en $dbuser y $dbpass.
 **************************************************************/

// --- 1) CONFIGURACIÓN DE CONEXIÓN -------------------------------------------
$dbhost = "localhost";
$dbname = "mi_db_juego";
$dbuser = "root";      // Ajustar según tu entorno
$dbpass = "";          // Ajustar según tu entorno

try {
    $pdo = new PDO("mysql:host=$dbhost;dbname=$dbname;charset=utf8", $dbuser, $dbpass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    die("Error de conexión: " . $e->getMessage());
}

// --- 2) SIMULACIÓN DE LOGIN ------------------------------------------------
// Para simplificar, un mini “login” que comprueba si recibimos user/password.
// Realmente deberías tener un formulario aparte, hashear contraseñas, etc.
session_start();

if (isset($_POST['action']) && $_POST['action'] === 'login') {
    $nombre = $_POST['nombre'] ?? '';
    $pass   = $_POST['pass']   ?? '';

    // Consultamos si el usuario existe en BD
    $stmt = $pdo->prepare("SELECT * FROM USUARIO WHERE Nombre = :nombre AND Contraseña = :pass");
    $stmt->execute([':nombre' => $nombre, ':pass' => $pass]);
    $usuario = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($usuario) {
        // Guardamos en sesión y recargamos
        $_SESSION['usuario_id'] = $usuario['Id_Usuario'];
        $_SESSION['usuario_nombre'] = $usuario['Nombre'];
        header("Location: index.php");
        exit;
    } else {
        $error = "Usuario/contraseña inválidos";
    }
}

// Cerrar sesión
if (isset($_GET['logout'])) {
    session_destroy();
    header("Location: index.php");
    exit;
}

// --- 3) SI ESTAMOS LOGUEADOS, OBTENER DATOS DE LA PARTIDA -------------------
$recursos = null;
$mensaje_accion = null;
if (isset($_SESSION['usuario_id'])) {
    // Obtener la fila de PARTIDA asociada al usuario
    $stmt = $pdo->prepare("
        SELECT p.Id_Partida, p.Madera, p.Ladrillo, p.Oro, p.Numero_Casas, u.Nombre 
          FROM PARTIDA p
          JOIN USUARIO u ON u.Id_Usuario = p.Id_Usuario
         WHERE p.Id_Usuario = :user_id
         LIMIT 1
    ");
    $stmt->execute([':user_id' => $_SESSION['usuario_id']]);
    $recursos = $stmt->fetch(PDO::FETCH_ASSOC);

    // --- 4) GESTIONAR ACCIONES (SUBIR NIVEL / RECLUTAR ALDEANOS) --------------
    if (isset($_POST['action']) && $_POST['action'] === 'subirCampMadera') {
        // Llamamos al procedure subir_nivel_campamento_madera
        if ($recursos) {
            $idPartida = $recursos['Id_Partida'];
            try {
                $sp = $pdo->prepare("CALL subir_nivel_campamento_madera(:pId)");
                $sp->bindParam(':pId', $idPartida, PDO::PARAM_INT);
                $sp->execute();
                // El procedure hace un SELECT con el mensaje
                $resultProc = $sp->fetchAll(PDO::FETCH_ASSOC);
                if ($resultProc) {
                    foreach ($resultProc as $row) {
                        $mensaje_accion = $row['Mensaje'] ?? "Procedimiento ejecutado.";
                    }
                }
                // Volver a cargar los datos de PARTIDA
                $stmt->execute([':user_id' => $_SESSION['usuario_id']]);
                $recursos = $stmt->fetch(PDO::FETCH_ASSOC);
            } catch (PDOException $e) {
                $mensaje_accion = "Error al subir nivel: " . $e->getMessage();
            }
        }
    }

    if (isset($_POST['action']) && $_POST['action'] === 'reclutarAldeano') {
        // Reclutamiento de aldeano => cuesta X oro (ejemplo: 50)
        $costeAldeano = 50; // Ajustar según tabla PARAMETROS, etc.
        if ($recursos && $recursos['Oro'] >= $costeAldeano) {
            $idPartida = $recursos['Id_Partida'];
            // 1) Verificar límite de aldeanos en base a casas (5 aldeanos x casa)
            //    Un ejemplo rápido: contar aldeanos ya reclutados
            $stmtCount = $pdo->prepare("SELECT COUNT(*) AS num FROM ALDEANOS WHERE Id_Partida=:p");
            $stmtCount->execute([':p' => $idPartida]);
            $filaCount = $stmtCount->fetch(PDO::FETCH_ASSOC);
            $aldeanosActuales = $filaCount['num'] ?? 0;

            $limite = $recursos['Numero_Casas'] * 5;
            if ($aldeanosActuales < $limite) {
                // Suficiente oro y hay espacio:
                // 2) Insertar nuevo aldeano
                $stmtIns = $pdo->prepare("
                    INSERT INTO ALDEANOS (Estado, Id_Partida) 
                    VALUES ('Descansando', :p)
                ");
                $stmtIns->execute([':p' => $idPartida]);

                // 3) Descontar oro de PARTIDA
                $stmtUpd = $pdo->prepare("
                    UPDATE PARTIDA 
                       SET Oro = Oro - :coste
                     WHERE Id_Partida = :idPartida
                ");
                $stmtUpd->execute([':coste' => $costeAldeano, ':idPartida' => $idPartida]);

                $mensaje_accion = "Aldeano reclutado con éxito. -$costeAldeano Oro";
            } else {
                $mensaje_accion = "No puedes reclutar más aldeanos (límite alcanzado).";
            }
            // Recargar datos PARTIDA
            $stmt->execute([':user_id' => $_SESSION['usuario_id']]);
            $recursos = $stmt->fetch(PDO::FETCH_ASSOC);
        } else {
            $mensaje_accion = "No hay suficiente Oro para reclutar un aldeano.";
        }
    }
}

// --- 5) MOSTRAR HTML -----
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Clash of Bases - Demo</title>
    <!-- Simple Boostrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-dark text-light">

<div class="container my-4">
    <h1 class="text-center mb-4">Clash of Bases</h1>

    <?php if (!isset($_SESSION['usuario_id'])): ?>
        <!-- FORM LOGIN -->
        <div class="row justify-content-center">
          <div class="col-md-4">
            <div class="card text-dark">
              <div class="card-body">
                <h4 class="card-title text-center">Iniciar Sesión</h4>
                <?php if (!empty($error)): ?>
                  <div class="alert alert-danger"><?= htmlspecialchars($error) ?></div>
                <?php endif; ?>
                <form method="POST">
                  <div class="mb-3">
                    <label for="nombre" class="form-label">Usuario</label>
                    <input type="text" name="nombre" class="form-control" required>
                  </div>
                  <div class="mb-3">
                    <label for="pass" class="form-label">Contraseña</label>
                    <input type="password" name="pass" class="form-control" required>
                  </div>
                  <input type="hidden" name="action" value="login">
                  <button type="submit" class="btn btn-primary w-100">Acceder</button>
                </form>
              </div>
            </div>
          </div>
        </div>

    <?php else: ?>
        <!-- VISTA DE JUGADOR CONECTADO -->
        <div class="mb-2 text-end">
            <a href="?logout" class="btn btn-sm btn-secondary">Cerrar Sesión</a>
        </div>

        <h2 class="text-center">Bienvenido, <?= htmlspecialchars($_SESSION['usuario_nombre']) ?></h2>

        <?php if ($recursos): ?>
          <div class="text-center my-3">
            <h4>Tus Recursos</h4>
            <p>
              <strong>Madera</strong>: <?= $recursos['Madera'] ?>
              &nbsp; | &nbsp;
              <strong>Ladrillo</strong>: <?= $recursos['Ladrillo'] ?>
              &nbsp; | &nbsp;
              <strong>Oro</strong>: <?= $recursos['Oro'] ?>
              &nbsp; | &nbsp;
              <strong>Casas</strong>: <?= $recursos['Numero_Casas'] ?>
            </p>
          </div>
        <?php endif; ?>

        <!-- Mostrar mensaje de acción si existe -->
        <?php if ($mensaje_accion): ?>
          <div class="alert alert-info text-dark text-center">
            <?= htmlspecialchars($mensaje_accion) ?>
          </div>
        <?php endif; ?>

        <!-- BOTONES DE ACCION -->
        <div class="text-center my-4">
          <form method="POST" class="d-inline">
            <input type="hidden" name="action" value="subirCampMadera">
            <button type="submit" class="btn btn-warning">
              Subir Nivel Campamento Madera
            </button>
          </form>

          <form method="POST" class="d-inline ms-2">
            <input type="hidden" name="action" value="reclutarAldeano">
            <button type="submit" class="btn btn-info">
              Reclutar Aldeano (50 Oro)
            </button>
          </form>
        </div>

        <!-- MOSTRAR RANKING -->
        <div class="card text-dark my-4">
          <div class="card-header">Ranking de Jugadores (por Oro)</div>
          <div class="card-body">
            <?php
              $stmtRank = $pdo->query("SELECT * FROM V_RANKING ORDER BY Posicion");
              $ranking = $stmtRank->fetchAll(PDO::FETCH_ASSOC);
            ?>
            <table class="table table-striped table-bordered">
              <thead>
                <tr>
                  <th>Posición</th>
                  <th>Nombre</th>
                  <th>Oro</th>
                </tr>
              </thead>
              <tbody>
                <?php foreach($ranking as $jug): ?>
                  <tr>
                    <td><?= $jug['Posicion'] ?></td>
                    <td><?= htmlspecialchars($jug['Nombre']) ?></td>
                    <td><?= $jug['Oro'] ?></td>
                  </tr>
                <?php endforeach; ?>
              </tbody>
            </table>
          </div>
        </div>

    <?php endif; ?>
</div>

<!-- Opcional: Bootstrap JS -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
