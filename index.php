<?php
session_start();

// Conexión a la base de datos
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

// Obtener parámetros globales para mostrar el coste de construcción de un campamento
$stmtParam = $pdo->query("SELECT Coste_Campamento FROM PARAMETROS LIMIT 1");
$param = $stmtParam->fetch(PDO::FETCH_ASSOC);
$costeCampamento = $param ? $param['Coste_Campamento'] : '---';

// Modo AJAX: Actualización dinámica de datos
if (isset($_GET['update']) && $_GET['update'] == 1) {
    if (!isset($_SESSION['usuario_id'])) {
        header('Content-Type: application/json');
        echo json_encode(['error' => 'No autorizado']);
        exit;
    }
    $data = [];
    $stmt = $pdo->prepare("SELECT * FROM PARTIDA WHERE Id_Usuario = :u LIMIT 1");
    $stmt->execute([':u' => $_SESSION['usuario_id']]);
    $data['partida'] = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($data['partida']) {
        $stmt = $pdo->prepare("SELECT * FROM CAMPAMENTOS WHERE Id_Partida = :p");
        $stmt->execute([':p' => $data['partida']['Id_Partida']]);
        $data['campamentos'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $stmt = $pdo->prepare("SELECT * FROM ALDEANOS WHERE Id_Partida = :p");
        $stmt->execute([':p' => $data['partida']['Id_Partida']]);
        $data['aldeanos'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $stmt = $pdo->query("SELECT * FROM V_RANKING_COMPLETO");
        $data['ranking'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    header('Content-Type: application/json');
    echo json_encode($data);
    exit;
}

// Logout
if (isset($_GET['logout'])) {
    session_destroy();
    header("Location: index.php");
    exit;
}

$mensaje = "";
$mensajeAccion = "";
$debugInfo = "";

// Procesar Login
if (!isset($_SESSION['usuario_id']) && isset($_POST['action']) && $_POST['action'] === 'login') {
    $nombre = $_POST['nombre'] ?? '';
    $pass = $_POST['pass'] ?? '';
    $stmt = $pdo->prepare("SELECT Id_Usuario, Nombre FROM USUARIO WHERE Nombre = :n AND Contraseña = :p LIMIT 1");
    $stmt->execute([':n' => $nombre, ':p' => $pass]);
    $usuario = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($usuario) {
        $_SESSION['usuario_id'] = $usuario['Id_Usuario'];
        $_SESSION['usuario_nombre'] = $usuario['Nombre'];
        header("Location: index.php");
        exit;
    } else {
        $mensaje = "Usuario/contraseña inválidos";
    }
}

// Cargar datos de la partida y datos adicionales
$partida = null;
$aldeanosDisponibles = []; // Aldeanos con estado "Descansando"
$campamentos = [];         // Todos los campamentos de la partida
if (isset($_SESSION['usuario_id'])) {
    $stmt = $pdo->prepare("SELECT * FROM PARTIDA WHERE Id_Usuario = :u LIMIT 1");
    $stmt->execute([':u' => $_SESSION['usuario_id']]);
    $partida = $stmt->fetch(PDO::FETCH_ASSOC);
    $debugInfo .= "DEBUG - Sesión:\n" . print_r($_SESSION, true) . "\n";
    $debugInfo .= "DEBUG - Partida:\n" . print_r($partida, true) . "\n";
    if ($partida) {
        $stmt = $pdo->prepare("SELECT * FROM ALDEANOS WHERE Id_Partida = :p AND Estado = 'Descansando'");
        $stmt->execute([':p' => $partida['Id_Partida']]);
        $aldeanosDisponibles = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $stmt = $pdo->prepare("SELECT * FROM CAMPAMENTOS WHERE Id_Partida = :p");
        $stmt->execute([':p' => $partida['Id_Partida']]);
        $campamentos = $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}

// Función para obtener costo de mejora (para tooltips)
function getImprovementCost($pdo, $campamentos, $tipo) {
    foreach ($campamentos as $camp) {
        if ($camp['Tipo'] === $tipo) {
            $nextLevel = $camp['Nivel'] + 1;
            $stmt = $pdo->prepare("SELECT * FROM DATOS_CAMPAMENTOS WHERE Tipo = :t AND Nivel = :n LIMIT 1");
            $stmt->execute([':t' => $tipo, ':n' => $nextLevel]);
            $mejora = $stmt->fetch(PDO::FETCH_ASSOC);
            if ($mejora) {
                return "Costo: Madera = " . $mejora['Coste_Madera_Mejora'] .
                       " / Ladrillo = " . $mejora['Coste_Ladrillo_Mejora'];
            }
        }
    }
    return "Sin datos (nivel máximo)";
}

// Procesar acciones del juego
if ($partida && isset($_POST['action']) && $_POST['action'] !== 'login') {
    $action = $_POST['action'];
    $idPartida = $partida['Id_Partida'];
    try {
        if ($action === 'asignarAldeano') {
            $aldeanoId = $_POST['aldeanoId'] ?? 0;
            $campamentoId = (isset($_POST['campamentoId']) && $_POST['campamentoId'] !== "") ? $_POST['campamentoId'] : 0;
            $sp = $pdo->prepare("CALL asignar_aldeano_a_campamento(:a, :c)");
            $sp->bindValue(':a', $aldeanoId, PDO::PARAM_INT);
            $sp->bindValue(':c', $campamentoId, PDO::PARAM_INT);
            $sp->execute();
            $res = $sp->fetchAll(PDO::FETCH_ASSOC);
            if ($res) {
                foreach ($res as $row) {
                    if (!empty($row['Mensaje'])) {
                        $mensajeAccion .= htmlspecialchars($row['Mensaje']) . "<br>";
                    }
                }
            } else {
                $mensajeAccion .= "Operación de reasignación completada.<br>";
            }
        } elseif ($action === 'upgradeCamp') {
            $campId = $_POST['campId'] ?? 0;
            if ($campId) {
                $sp = $pdo->prepare("CALL subir_nivel_campamento_por_id(:campId, :p)");
                $sp->bindValue(':campId', $campId, PDO::PARAM_INT);
                $sp->bindValue(':p', $idPartida, PDO::PARAM_INT);
                $sp->execute();
                $res = $sp->fetchAll(PDO::FETCH_ASSOC);
                if ($res) {
                    foreach ($res as $row) {
                        if (!empty($row['Mensaje'])) {
                            $mensajeAccion .= htmlspecialchars($row['Mensaje']) . "<br>";
                        }
                    }
                } else {
                    $mensajeAccion .= "Campamento #$campId mejorado correctamente.<br>";
                }
            }
        } else {
            $sp = null;
            switch ($action) {
                case 'construirCasa':
                    $sp = $pdo->prepare("CALL construir_casa(:p)");
                    $sp->bindValue(':p', $idPartida, PDO::PARAM_INT);
                    break;
                case 'reclutarAldeano':
                    $sp = $pdo->prepare("CALL reclutar_aldeano(:p)");
                    $sp->bindValue(':p', $idPartida, PDO::PARAM_INT);
                    break;
                case 'crearCampamento':
                    $tipoCamp = $_POST['tipoCamp'] ?? '';
                    if (!empty($tipoCamp)) {
                        $sp = $pdo->prepare("CALL crear_campamento(:p, :t)");
                        $sp->bindValue(':p', $idPartida, PDO::PARAM_INT);
                        $sp->bindValue(':t', $tipoCamp, PDO::PARAM_STR);
                    }
                    break;
            }
            if ($sp) {
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
        }
        // Actualizar datos de la partida tras la acción
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
  <title>ℭ𝔩𝔞𝔰𝔥 𝔒𝔣 𝔅𝔞𝔰𝔢𝔰 - Gestión de Recursos</title>
  <!-- Bootstrap CSS -->
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/css/bootstrap.min.css">
  <!-- FontAwesome -->
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.1.1/css/all.min.css">
  <style>
    body {
      background-color: #1c1c1c;
      color: #e0e0e0;
      font-family: 'Open Sans', sans-serif;
    }
    .card {
      border-radius: 10px;
      margin-bottom: 1rem;
    }
    .btn {
      border-radius: 5px;
    }
    .resource {
      font-size: 1.2em;
    }
    .section-title {
      border-bottom: 2px solid #444;
      padding-bottom: 0.5rem;
      margin-bottom: 1rem;
    }
    .badge-cost {
      font-size: 0.8em;
      margin-left: 5px;
    }
    .navbar-brand, .nav-link {
      font-weight: 600;
    }
    #debugPanel {
      display: none;
      white-space: pre-wrap;
    }
  </style>
</head>
<body>
  <!-- Navbar fija -->
  <nav class="navbar navbar-expand-lg navbar-dark bg-dark fixed-top">
    <div class="container-fluid">
      <a class="navbar-brand" href="#"><i class="fas fa-gamepad"></i> ℭ𝔩𝔞𝔰𝔥 𝔒𝔣 𝔅𝔞𝔰𝔢𝔰</a>
      <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarMenu" 
              aria-controls="navbarMenu" aria-expanded="false" aria-label="Toggle navigation">
        <span class="navbar-toggler-icon"></span>
      </button>
      <div class="collapse navbar-collapse" id="navbarMenu">
        <ul class="navbar-nav me-auto mb-2 mb-lg-0">

        </ul>
        <div class="d-flex">
          <button class="btn btn-sm btn-warning me-2" id="btnDebug"><i class="fas fa-bug"></i> Debug</button>
          <a href="?logout" class="btn btn-sm btn-secondary"><i class="fas fa-sign-out-alt"></i> Cerrar Sesión</a>
        </div>
      </div>
    </div>
  </nav>

  <div class="container" style="margin-top:90px;">
    <?php if (!isset($_SESSION['usuario_id'])): ?>
      <!-- Formulario de Login -->
      <div class="row justify-content-center">
        <div class="col-md-4">
          <div class="card bg-light text-dark">
            <div class="card-body">
              <?php if (!empty($mensaje)): ?>
                <div class="alert alert-danger text-center"><?= htmlspecialchars($mensaje) ?></div>
              <?php endif; ?>
              <h4 class="text-center mb-3">Iniciar Sesión</h4>
              <form method="POST">
                <div class="mb-3">
                  <label class="form-label"><i class="fas fa-user"></i> Usuario</label>
                  <input type="text" name="nombre" class="form-control" required>
                </div>
                <div class="mb-3">
                  <label class="form-label"><i class="fas fa-lock"></i> Contraseña</label>
                  <input type="password" name="pass" class="form-control" required>
                </div>
                <input type="hidden" name="action" value="login">
                <button type="submit" class="btn btn-primary w-100"><i class="fas fa-sign-in-alt"></i> Ingresar</button>
              </form>
            </div>
          </div>
        </div>
      </div>
    <?php else: ?>
      <!-- Dashboard Principal -->
      <h4 id="dashboard" class="text-center mb-4">Bienvenido, <?= htmlspecialchars($_SESSION['usuario_nombre']) ?></h4>
      <?php if (!empty($mensajeAccion)): ?>
        <div class="alert alert-info text-dark text-center"><?= nl2br($mensajeAccion) ?></div>
      <?php endif; ?>

      <!-- Sección: Resumen de Partida -->
      <div class="row mb-4">
        <!-- Recursos -->
        <div class="col-md-4">
          <div class="card bg-secondary text-white">
            <div class="card-header"><i class="fas fa-coins"></i> Recursos</div>
            <div class="card-body">
              <?php if ($partida): ?>
                <p class="resource"><i class="fas fa-tree"></i> Madera: <span id="resourceWood"><?= $partida['Madera'] ?></span></p>
                <p class="resource"><i class="fa-solid fa-trowel"></i> Ladrillo: <span id="resourceBrick"><?= $partida['Ladrillo'] ?></span></p>
                <p class="resource"><i class="fas fa-coins"></i> Oro: <span id="resourceGold"><?= $partida['Oro'] ?></span></p>
              <?php endif; ?>
            </div>
          </div>
        </div>
        <!-- Infraestructura -->
        <div class="col-md-4">
          <div class="card bg-secondary text-white">
            <div class="card-header"><i class="fas fa-home"></i> Infraestructura</div>
            <div class="card-body">
            <?php if ($partida): 
                // Consulta para contar todos los aldeanos de la partida
                $stmtTotal = $pdo->prepare("SELECT COUNT(*) AS total FROM ALDEANOS WHERE Id_Partida = :p");
                $stmtTotal->execute([':p' => $partida['Id_Partida']]);
                $totalAldeanos = $stmtTotal->fetch(PDO::FETCH_ASSOC)['total'];
            ?>
              <p class="resource">Casas: <span id="resourceHouses"><?= $partida['Numero_Casas'] ?></span></p>
              <p class="resource">Aldeanos Totales: <span><?= $totalAldeanos ?></span></p>
              <p class="resource">Aldeanos Disponibles: <span><?= count($aldeanosDisponibles) ?></span></p>
            <?php endif; ?>

            </div>
          </div>
        </div>
        <!-- Acciones Rápidas -->
        <div class="col-md-4">
          <div class="card bg-dark text-white">
            <div class="card-header text-center"><i class="fas fa-tools"></i> Acciones Rápidas</div>
            <div class="card-body">
              <div class="row g-2">
                <!-- Construir Casa -->
                <div class="col-md-6">
                  <div class="card bg-light text-dark">
                    <div class="card-body text-center">
                      <i class="fas fa-building fa-2x"></i>
                      <p class="mt-2 mb-1">Construir Casa</p>
                      <span class="badge bg-warning badge-cost">Costo: <?= $partida ? ($partida['Numero_Casas'] * 100) : '---' ?> (Madera/Ladrillo)</span>
                      <form method="POST" class="mt-2">
                        <input type="hidden" name="action" value="construirCasa">
                        <button type="submit" class="btn btn-warning btn-sm w-100">Construir</button>
                      </form>
                    </div>
                  </div>
                </div>
                <!-- Reclutar Aldeano -->
                <div class="col-md-6">
                  <div class="card bg-light text-dark">
                    <div class="card-body text-center">
                      <i class="fas fa-user-plus fa-2x"></i>
                      <p class="mt-2 mb-1">Reclutar Aldeano</p>
                      <span class="badge bg-info badge-cost">Costo: <?= $partida ? 50 : '---' ?> Oro</span>
                      <form method="POST" class="mt-2">
                        <input type="hidden" name="action" value="reclutarAldeano">
                        <button type="submit" class="btn btn-info btn-sm w-100">Reclutar</button>
                      </form>
                    </div>
                  </div>
                </div>
                <!-- Panel de Construcción de Campamentos -->
                <div class="col-12">
                  <div class="card bg-light text-dark">
                    <div class="card-body text-center">
                      <i class="fas fa-hammer fa-2x text-primary"></i>
                      <p class="mt-2 mb-1">Costos de Construcción</p>
                      <div class="row">
                        <!-- Campamento de Madera -->
                        <div class="col-md-4">
                          <div class="card border-primary">
                            <div class="card-header bg-primary text-white">Madera</div>
                            <div class="card-body">
                              <p class="card-text">Madera: <?= $costeCampamento ?></p>
                              <p class="card-text">Ladrillo: <?= $costeCampamento ?></p>
                            </div>
                          </div>
                        </div>
                        <!-- Campamento de Ladrillo -->
                        <div class="col-md-4">
                          <div class="card border-warning">
                            <div class="card-header bg-warning text-dark">Ladrillo</div>
                            <div class="card-body">
                              <p class="card-text">Madera: <?= $costeCampamento ?></p>
                              <p class="card-text">Ladrillo: <?= $costeCampamento ?></p>
                            </div>
                          </div>
                        </div>
                        <!-- Campamento de Oro -->
                        <div class="col-md-4">
                          <div class="card border-success">
                            <div class="card-header bg-success text-white">Oro</div>
                            <div class="card-body">
                              <p class="card-text">Oro: <?= $costeCampamento ?></p>
                            </div>
                          </div>
                        </div>
                      </div>
                      <!-- Formulario para crear un nuevo campamento -->
                      <form method="POST" class="d-inline mt-3">
                        <select name="tipoCamp" class="form-select d-inline w-auto me-2" required>
                          <option value="">-- Tipo --</option>
                          <option value="Madera">Madera</option>
                          <option value="Ladrillo">Ladrillo</option>
                          <option value="Oro">Oro</option>
                        </select>
                        <input type="hidden" name="action" value="crearCampamento">
                        <button type="submit" class="btn btn-primary btn-sm">Crear Campamento</button>
                      </form>
                    </div>
                  </div>
                </div>
              </div><!-- Fin row Acciones -->
            </div>
          </div>
        </div>
      </div>
      
      <!-- Sección: Campamentos -->
      <div id="campamentosSection" class="mb-4">
        <h5 class="section-title text-white"><i class="fas fa-warehouse"></i> Mis Campamentos</h5>
        <div class="row">
          <?php if (!empty($campamentos)): ?>
            <?php foreach ($campamentos as $camp): ?>
              <div class="col-md-4 mb-3">
                <div class="card bg-light text-dark">
                  <div class="card-header">
                    <?php
                      if ($camp['Tipo'] === 'Madera') {
                          echo '<i class="fas fa-tree"></i> Campamento de Madera';
                      } elseif ($camp['Tipo'] === 'Ladrillo') {
                          echo '<i class="fa-solid fa-trowel"></i> Campamento de Ladrillo';
                      } elseif ($camp['Tipo'] === 'Oro') {
                          echo '<i class="fas fa-coins"></i> Campamento de Oro';
                      }
                    ?>
                  </div>
                  <div class="card-body">
                    <p><strong>Nivel:</strong> <?= $camp['Nivel'] ?></p>
                    <?php 
                      $stmtCount = $pdo->prepare("SELECT COUNT(*) AS total FROM ALDEANOS WHERE Id_Campamentos = :campId");
                      $stmtCount->execute([':campId' => $camp['Id_Campamentos']]);
                      $countData = $stmtCount->fetch(PDO::FETCH_ASSOC);
                      $totalTrabajadores = $countData['total'];
                    ?>
                    <p><strong>Trabajadores:</strong> <?= $totalTrabajadores ?></p>
                    <?php
                      $stmt2 = $pdo->prepare("SELECT * FROM DATOS_CAMPAMENTOS WHERE Tipo = :t AND Nivel = :n LIMIT 1");
                      $stmt2->execute([':t' => $camp['Tipo'], ':n' => $camp['Nivel'] + 1]);
                      $mejora = $stmt2->fetch(PDO::FETCH_ASSOC);
                      if ($mejora):
                        echo '<p><strong>Próxima Mejora:</strong> Madera = ' . $mejora['Coste_Madera_Mejora'] .
                             ' / Ladrillo = ' . $mejora['Coste_Ladrillo_Mejora'] . '</p>';
                      else:
                        echo '<p><em>Nivel máximo</em></p>';
                      endif;
                    ?>
                    <?php if ($camp['Nivel'] < 5): ?>
                      <form method="POST" class="mt-2">
                        <input type="hidden" name="action" value="upgradeCamp">
                        <input type="hidden" name="campId" value="<?= $camp['Id_Campamentos'] ?>">
                        <button type="submit" class="btn btn-success btn-sm w-100"><i class="fas fa-arrow-up"></i> Mejorar</button>
                      </form>
                    <?php endif; ?>
                  </div>
                </div>
              </div>
            <?php endforeach; ?>
          <?php else: ?>
            <div class="col-12">
              <p class="text-center text-white">No tienes campamentos registrados.</p>
            </div>
          <?php endif; ?>
        </div>
      </div>
      
      <!-- Sección: Aldeanos -->
<div id="aldeanosSection" class="mb-4">
  <h5 class="section-title text-white"><i class="fas fa-users"></i> Mis Aldeanos</h5>
  
  <!-- Menú para ordenar -->
  <div class="d-flex justify-content-end mb-3">
    <a href="?sort=campamento" class="btn btn-sm btn-outline-primary me-2">Ordenar por Campamento</a>
    <a href="?sort=disponibilidad" class="btn btn-sm btn-outline-success">Ordenar por Disponibilidad</a>
  </div>
  
  <div class="row">
    <?php
      // Obtener el criterio de ordenación vía GET
      $sort = $_GET['sort'] ?? '';
      
      if ($sort === 'campamento') {
          // Ordena primero los aldeanos asignados (no NULL) y luego por Id_Campamentos
          $stmt = $pdo->prepare("SELECT * FROM ALDEANOS WHERE Id_Partida = :p ORDER BY (Id_Campamentos IS NULL), Id_Campamentos");
      } elseif ($sort === 'disponibilidad') {
          // Ordena poniendo primero los aldeanos 'Descansando'
          $stmt = $pdo->prepare("SELECT * FROM ALDEANOS WHERE Id_Partida = :p ORDER BY (Estado='Descansando') DESC");
      } else {
          // Sin ordenación especial
          $stmt = $pdo->prepare("SELECT * FROM ALDEANOS WHERE Id_Partida = :p");
      }
      
      $stmt->execute([':p' => $partida['Id_Partida']]);
      $aldeanos = $stmt->fetchAll(PDO::FETCH_ASSOC);
      
      // Crear un mapa para identificar el campamento asignado
      $campMap = [];
      foreach ($campamentos as $camp) {
          $campMap[$camp['Id_Campamentos']] = $camp;
      }
    ?>
    <?php if (!empty($aldeanos)): ?>
      <?php foreach ($aldeanos as $ald): ?>
        <div class="col-md-3 mb-3">
          <div class="card bg-light text-dark">
            <div class="card-header">Aldeano #<?= $ald['Id_Aldeanos'] ?></div>
            <div class="card-body">
              <p><strong>Estado:</strong> <?= htmlspecialchars($ald['Estado']) ?></p>
              <?php if (!empty($ald['Id_Campamentos'])): 
                $camp = $campMap[$ald['Id_Campamentos']] ?? null;
              ?>
                <p><strong>Camp.:</strong> #<?= htmlspecialchars($ald['Id_Campamentos']) ?> (<?= $camp ? htmlspecialchars($camp['Tipo']) : "Desconocido" ?>)</p>
              <?php elseif (!empty($ald['Id_Casa'])): ?>
                <p><strong>Casa:</strong> #<?= htmlspecialchars($ald['Id_Casa']) ?></p>
              <?php else: ?>
                <p><strong>No asignado</strong></p>
              <?php endif; ?>
              <button class="btn btn-sm btn-outline-primary reasignarBtn w-100 mt-2" data-ald="<?= $ald['Id_Aldeanos'] ?>">
                Reasignar
              </button>
            </div>
          </div>
        </div>
      <?php endforeach; ?>
    <?php else: ?>
      <div class="col-12">
        <p class="text-center text-white">No tienes aldeanos registrados.</p>
      </div>
    <?php endif; ?>
  </div>
</div>

      
      <!-- Modal para Reasignar Aldeano -->
      <div class="modal fade" id="reasignarModal" tabindex="-1" aria-labelledby="reasignarModalLabel" aria-hidden="true">
        <div class="modal-dialog">
          <form method="POST" id="reasignarForm">
            <div class="modal-content">
              <div class="modal-header">
                <h5 class="modal-title" id="reasignarModalLabel"><i class="fas fa-exchange-alt"></i> Reasignar Aldeano</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
              </div>
              <div class="modal-body">
                <input type="hidden" name="action" value="asignarAldeano">
                <input type="hidden" name="aldeanoId" id="modalAldeanoId">
                <div class="mb-3">
                  <label class="form-label"><i class="fas fa-warehouse"></i> Seleccionar Nuevo Campamento</label>
                  <select name="campamentoId" class="form-select" required>
                    <option value="0">Sin asignar</option>
                    <?php foreach ($campamentos as $camp): ?>
                      <option value="<?= $camp['Id_Campamentos'] ?>">
                        <?php
                          if ($camp['Tipo'] === 'Madera') {
                              echo 'Camp. Madera (#' . $camp['Id_Campamentos'] . ')';
                          } elseif ($camp['Tipo'] === 'Ladrillo') {
                              echo 'Camp. Ladrillo (#' . $camp['Id_Campamentos'] . ')';
                          } elseif ($camp['Tipo'] === 'Oro') {
                              echo 'Camp. Oro (#' . $camp['Id_Campamentos'] . ')';
                          }
                        ?>
                      </option>
                    <?php endforeach; ?>
                  </select>
                </div>
              </div>
              <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                <button type="submit" class="btn btn-primary"><i class="fas fa-paper-plane"></i> Reasignar</button>
              </div>
            </div>
          </form>
        </div>
      </div>
      
      <!-- Sección: Ranking -->
      <div id="rankingSection" class="mb-4">
        <h5 class="section-title text-white"><i class="fas fa-trophy"></i> Ranking de Partidas</h5>
        <div class="card bg-light text-dark">
          <div class="card-body table-responsive">
            <?php
              try {
                  $stmtRank = $pdo->query("SELECT * FROM V_RANKING_COMPLETO");
                  $ranking = $stmtRank->fetchAll(PDO::FETCH_ASSOC);
            ?>
            <table class="table table-bordered table-striped">
              <thead>
                <tr>
                  <th><i class="fas fa-sort-numeric-down"></i> Pos.</th>
                  <th><i class="fas fa-user"></i> Jugador</th>
                  <th><i class="fas fa-tree"></i> Madera</th>
                  <th><i class="fa-solid fa-trowel"></i> Ladrillo</th>
                  <th><i class="fas fa-coins"></i> Oro</th>
                  <th><i class="fas fa-home"></i> Casas</th>
                  <th><i class="fas fa-warehouse"></i> Camp.</th>
                  <th><i class="fas fa-users"></i> Aldeanos</th>
                  <th><i class="fas fa-medal"></i> Puntaje</th>
                </tr>
              </thead>
              <tbody>
                <?php foreach ($ranking as $index => $r): ?>
                  <tr>
                    <td><?= ($index + 1) ?></td>
                    <td><?= htmlspecialchars($r['Nombre'] ?? '') ?></td>
                    <td><?= htmlspecialchars($r['Madera'] ?? '') ?></td>
                    <td><?= htmlspecialchars($r['Ladrillo'] ?? '') ?></td>
                    <td><?= htmlspecialchars($r['Oro'] ?? '') ?></td>
                    <td><?= htmlspecialchars($r['Numero_Casas'] ?? '') ?></td>
                    <td><?= htmlspecialchars($r['TotalCampamentos'] ?? 0) ?></td>
                    <td><?= htmlspecialchars($r['TotalAldeanos'] ?? 0) ?></td>
                    <td><?= htmlspecialchars($r['Puntaje'] ?? '') ?></td>
                  </tr>
                <?php endforeach; ?>
              </tbody>
            </table>
            <?php
                  } catch (Exception $ex) {
                      echo "<div class='alert alert-danger'>Error al cargar el Ranking: " . htmlspecialchars($ex->getMessage()) . "</div>";
                  }
            ?>
          </div>
        </div>
      </div>
    <?php endif; ?>
  </div>

  <!-- Bootstrap JS y dependencias -->
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/js/bootstrap.bundle.min.js"></script>
  <!-- AJAX: Actualización dinámica cada 5 segundos -->
  <script>
    async function fetchGameData() {
      try {
        const response = await fetch("index.php?update=1");
        if (!response.ok) throw new Error("Error en la actualización");
        const data = await response.json();
        if (data.partida) {
          document.getElementById("resourceWood").innerText = data.partida.Madera;
          document.getElementById("resourceBrick").innerText = data.partida.Ladrillo;
          document.getElementById("resourceGold").innerText = data.partida.Oro;
          document.getElementById("resourceHouses").innerText = data.partida.Numero_Casas;
          // Aquí podrías actualizar otros elementos dinámicamente, si se requiere
        }
      } catch (error) {
        console.error("Error al actualizar los datos del juego:", error);
      }
    }
    setInterval(fetchGameData, 5000);

    // Toggle para panel de Debug
    document.getElementById('btnDebug').addEventListener('click', function() {
      var debugPanel = document.getElementById('debugPanel');
      debugPanel.style.display = (debugPanel.style.display === 'none' || debugPanel.style.display === '') ? 'block' : 'none';
    });

    // Modal de Reasignación
    var reasignarBtns = document.querySelectorAll('.reasignarBtn');
    reasignarBtns.forEach(function(btn) {
      btn.addEventListener('click', function() {
        var idAldeano = this.getAttribute('data-ald');
        document.getElementById('modalAldeanoId').value = idAldeano;
        var modal = new bootstrap.Modal(document.getElementById('reasignarModal'));
        modal.show();
      });
    });
    
    // Inicializar tooltips
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function (tooltipTriggerEl) {
      return new bootstrap.Tooltip(tooltipTriggerEl);
    });
  </script>
  
  <!-- Panel Debug (opcional) -->
  <div class="container mt-4">
    <div class="card bg-dark text-white" id="debugPanel">
      <div class="card-header"><i class="fas fa-bug"></i> Debug Info</div>
      <div class="card-body">
        <pre><?= htmlspecialchars($debugInfo) ?></pre>
      </div>
    </div>
  </div>
</body>
</html>
