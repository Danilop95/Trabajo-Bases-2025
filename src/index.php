<?php
session_start();

// Carga variables de entorno
$dbhost = getenv('DB_HOST') ?: 'localhost';
$dbname = getenv('DB_NAME') ?: 'mi_db_juego';
$dbuser = getenv('DB_USER') ?: 'root';
$dbpass = getenv('DB_PASS') ?: '';

try {
    $pdo = new PDO("mysql:host=$dbhost;dbname=$dbname;charset=utf8", $dbuser, $dbpass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    die("Error de conexión: " . $e->getMessage());
}

// Logout
if (isset($_GET['logout'])) {
    session_destroy();
    header("Location: index.php");
    exit;
}

$mensaje       = "";
$mensajeAccion = "";

// Login
if (!isset($_SESSION['usuario_id']) && isset($_POST['action']) && $_POST['action'] === 'login') {
    $nombre = $_POST['nombre'] ?? '';
    $pass   = $_POST['pass'] ?? '';
    $stmt = $pdo->prepare("SELECT Id_Usuario, Nombre FROM USUARIO WHERE Nombre = :n AND Contraseña = :p LIMIT 1");
    $stmt->execute([':n' => $nombre, ':p' => $pass]);
    $usuario = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($usuario) {
        $_SESSION['usuario_id']     = $usuario['Id_Usuario'];
        $_SESSION['usuario_nombre'] = $usuario['Nombre'];
        header("Location: index.php");
        exit;
    } else {
        $mensaje = "Usuario/contraseña inválidos";
    }
}

// Cargar datos de partida
$partida = null;
if (isset($_SESSION['usuario_id'])) {
    $stmt = $pdo->prepare("SELECT * FROM PARTIDA WHERE Id_Usuario = :u LIMIT 1");
    $stmt->execute([':u' => $_SESSION['usuario_id']]);
    $partida = $stmt->fetch(PDO::FETCH_ASSOC);
}

// Procesar acciones
if ($partida && isset($_POST['action'])) {
    $action    = $_POST['action'];
    $idPartida = $partida['Id_Partida'];

    try {
        $sp = null;
        switch ($action) {
            case 'construirCasa':
                $sp = $pdo->prepare("CALL construir_casa(:p)");
                break;
            case 'reclutarAldeano':
                $sp = $pdo->prepare("CALL reclutar_aldeano(:p)");
                break;
            case 'subirCampMadera':
                $sp = $pdo->prepare("CALL subir_nivel_campamento_madera(:p)");
                break;
            case 'asignarAldeano':
                $aldeanoId    = $_POST['aldeanoId'] ?? 0;
                $campamentoId = $_POST['campamentoId'] ?? 0;
                $sp = $pdo->prepare("CALL asignar_aldeano_campamento(:a, :c, :p)");
                $sp->bindValue(':a', $aldeanoId,    PDO::PARAM_INT);
                $sp->bindValue(':c', $campamentoId, PDO::PARAM_INT);
                break;
            case 'atacarPartida':
                $destino = $_POST['partidaDestino'] ?? 0;
                if ($destino == $idPartida) {
                    $mensajeAccion = "No puedes atacarte a ti mismo.";
                } else {
                    $sp = $pdo->prepare("CALL atacar_partida(:ori, :dest)");
                    $sp->bindValue(':dest', $destino, PDO::PARAM_INT);
                }
                break;
        }

        if ($sp) {
            $sp->bindValue(':p', $idPartida, PDO::PARAM_INT);
            $sp->execute();
            $res = $sp->fetchAll(PDO::FETCH_ASSOC);
            if ($res) {
                foreach ($res as $row) {
                    if (!empty($row['Mensaje'])) {
                        $mensajeAccion .= htmlspecialchars($row['Mensaje']) . "<br>";
                    }
                }
            }
        }

        $stmt = $pdo->prepare("SELECT * FROM PARTIDA WHERE Id_Partida = :p LIMIT 1");
        $stmt->execute([':p' => $idPartida]);
        $partida = $stmt->fetch(PDO::FETCH_ASSOC);

    } catch (Exception $e) {
        $mensajeAccion = "Error: " . htmlspecialchars($e->getMessage());
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Juego Estrategia</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/css/bootstrap.min.css">
</head>
<body class="bg-dark text-light">
<div class="container my-4">

  <h1 class="text-center mb-4">Juego de Estrategia</h1>

  <?php if (!isset($_SESSION['usuario_id'])): ?>
    <div class="row justify-content-center">
      <div class="col-md-4">
        <div class="card text-dark">
          <div class="card-body">
            <?php if ($mensaje): ?>
              <div class="alert alert-danger text-center"><?= htmlspecialchars($mensaje) ?></div>
            <?php endif; ?>
            <form method="POST">
              <div class="mb-3">
                <label>Usuario</label>
                <input type="text" name="nombre" class="form-control" required>
              </div>
              <div class="mb-3">
                <label>Contraseña</label>
                <input type="password" name="pass" class="form-control" required>
              </div>
              <input type="hidden" name="action" value="login">
              <button type="submit" class="btn btn-primary w-100">Iniciar Sesión</button>
            </form>
          </div>
        </div>
      </div>
    </div>
  <?php else: ?>
    <div class="text-end mb-2">
      <a href="?logout" class="btn btn-sm btn-secondary">Cerrar Sesión</a>
    </div>
    <h4 class="text-center">Bienvenido, <?= htmlspecialchars($_SESSION['usuario_nombre']) ?></h4>

    <?php if ($partida): ?>
      <div class="text-center my-3">
        Madera: <?= $partida['Madera'] ?> |
        Ladrillo: <?= $partida['Ladrillo'] ?> |
        Oro: <?= $partida['Oro'] ?> |
        Casas: <?= $partida['Numero_Casas'] ?>
      </div>
    <?php endif; ?>

    <?php if ($mensajeAccion): ?>
      <div class="alert alert-info text-dark text-center">
        <?= nl2br($mensajeAccion) ?>
      </div>
    <?php endif; ?>

    <div class="text-center my-4">
      <form method="POST" class="d-inline">
        <input type="hidden" name="action" value="construirCasa">
        <button type="submit" class="btn btn-warning mx-1">Construir Casa</button>
      </form>
      <form method="POST" class="d-inline">
        <input type="hidden" name="action" value="reclutarAldeano">
        <button type="submit" class="btn btn-info mx-1">Reclutar Aldeano</button>
      </form>
      <form method="POST" class="d-inline">
        <input type="hidden" name="action" value="subirCampMadera">
        <button type="submit" class="btn btn-success mx-1">Subir Camp. Madera</button>
      </form>
    </div>

    <div class="card text-dark mb-3">
      <div class="card-header">Asignar Aldeano a Campamento</div>
      <div class="card-body">
        <form method="POST" class="row g-3">
          <div class="col-sm-6">
            <label>ID Aldeano</label>
            <input type="number" name="aldeanoId" class="form-control" required>
          </div>
          <div class="col-sm-6">
            <label>ID Campamento</label>
            <input type="number" name="campamentoId" class="form-control" required>
          </div>
          <input type="hidden" name="action" value="asignarAldeano">
          <div class="col-12 text-end">
            <button type="submit" class="btn btn-primary">Asignar</button>
          </div>
        </form>
      </div>
    </div>

    <div class="card text-dark mb-3">
      <div class="card-header">Atacar Otra Partida</div>
      <div class="card-body">
        <form method="POST" class="row g-3">
          <div class="col-sm-8">
            <label>ID de la partida a atacar</label>
            <input type="number" name="partidaDestino" class="form-control" required>
          </div>
          <input type="hidden" name="action" value="atacarPartida">
          <div class="col-sm-4 text-end">
            <button type="submit" class="btn btn-danger w-100">Atacar</button>
          </div>
        </form>
      </div>
    </div>

    <div class="card text-dark">
      <div class="card-header">Ranking por Oro</div>
      <div class="card-body">
        <?php
          try {
              $stmtRank = $pdo->query("SELECT * FROM V_RANKING ORDER BY Posicion");
              $ranking = $stmtRank->fetchAll(PDO::FETCH_ASSOC);
        ?>
        <table class="table table-bordered">
          <thead>
            <tr>
              <th>Pos.</th>
              <th>Jugador</th>
              <th>Oro</th>
            </tr>
          </thead>
          <tbody>
          <?php foreach ($ranking as $r): ?>
            <tr>
              <td><?= $r['Posicion'] ?></td>
              <td><?= htmlspecialchars($r['Nombre']) ?></td>
              <td><?= $r['Oro'] ?></td>
            </tr>
          <?php endforeach; ?>
          </tbody>
        </table>
        <?php
          } catch (Exception $ex) {
              echo "<div class='alert alert-danger'>Error al cargar Ranking: ".htmlspecialchars($ex->getMessage())."</div>";
          }
        ?>
      </div>
    </div>
  <?php endif; ?>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
