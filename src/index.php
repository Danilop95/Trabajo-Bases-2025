<?php
session_start();

// Cargar variables de entorno (o usar valores por defecto)
$dbhost = getenv('DB_HOST') ?: 'localhost';
$dbname = getenv('DB_NAME') ?: 'mi_db_juego';
$dbuser = getenv('DB_USER') ?: 'root';
$dbpass = getenv('DB_PASS') ?: '';

// Conexión a la base de datos con PDO
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
$debugInfo     = "";

// Procesar Login
if (!isset($_SESSION['usuario_id']) && isset($_POST['action']) && $_POST['action'] === 'login') {
    $nombre = $_POST['nombre'] ?? '';
    $pass   = $_POST['pass'] ?? '';
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

// Cargar datos de partida y datos adicionales
$partida = null;
$aldeanosDisponibles = []; // aldeanos en estado 'Descansando'
$campamentos = [];         // todos los campamentos de la partida
if (isset($_SESSION['usuario_id'])) {
    $stmt = $pdo->prepare("SELECT * FROM PARTIDA WHERE Id_Usuario = :u LIMIT 1");
    $stmt->execute([':u' => $_SESSION['usuario_id']]);
    $partida = $stmt->fetch(PDO::FETCH_ASSOC);
    $debugInfo .= "DEBUG - Sesión:\n" . print_r($_SESSION, true) . "\n\n";
    $debugInfo .= "DEBUG - Partida:\n" . print_r($partida, true) . "\n";
    if ($partida) {
        $stmt = $pdo->prepare("SELECT Id_Aldeanos FROM ALDEANOS WHERE Id_Partida = :p AND Estado = 'Descansando'");
        $stmt->execute([':p' => $partida['Id_Partida']]);
        $aldeanosDisponibles = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $stmt = $pdo->prepare("SELECT Id_Campamentos, Tipo, Nivel, N_Trabajadores FROM CAMPAMENTOS WHERE Id_Partida = :p");
        $stmt->execute([':p' => $partida['Id_Partida']]);
        $campamentos = $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}

// Procesar acciones del juego
if ($partida && isset($_POST['action']) && $_POST['action'] !== 'login') {
    $action = $_POST['action'];
    $idPartida = $partida['Id_Partida'];
    try {
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
            case 'subirCampMadera':
                $sp = $pdo->prepare("CALL subir_nivel_campamento(:p, 'Madera')");
                $sp->bindValue(':p', $idPartida, PDO::PARAM_INT);
                break;
            case 'subirCampLadrillo':
                $sp = $pdo->prepare("CALL subir_nivel_campamento(:p, 'Ladrillo')");
                $sp->bindValue(':p', $idPartida, PDO::PARAM_INT);
                break;
            case 'subirCampOro':
                $sp = $pdo->prepare("CALL subir_nivel_campamento(:p, 'Oro')");
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
            case 'asignarAldeano':
                $aldeanoId = $_POST['aldeanoId'] ?? 0;
                $campamentoId = $_POST['campamentoId'] ?? 0;
                $sp = $pdo->prepare("CALL asignar_aldeano_a_campamento(:a, :c)");
                $sp->bindValue(':a', $aldeanoId, PDO::PARAM_INT);
                $sp->bindValue(':c', $campamentoId, PDO::PARAM_INT);
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
  <title>Juego de Estrategia</title>
  <!-- Bootstrap CSS -->
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/css/bootstrap.min.css">
  <!-- FontAwesome -->
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.1.1/css/all.min.css">
  <style>
    body { background-color: #222; }
    .card { border-radius: 10px; margin-bottom: 1rem; }
    .btn { border-radius: 5px; }
    .resource { font-size: 1.2em; }
    #debugPanel { display: none; white-space: pre-wrap; }
  </style>
</head>
<body class="text-light">
  <!-- Navbar -->
  <nav class="navbar navbar-expand-lg navbar-dark bg-dark mb-4">
    <div class="container-fluid">
      <a class="navbar-brand" href="#"><i class="fas fa-gamepad"></i> Estrategia</a>
      <div class="d-flex">
        <button class="btn btn-sm btn-warning me-2" id="btnDebug"><i class="fas fa-bug"></i> Debug</button>
        <a href="?logout" class="btn btn-sm btn-secondary"><i class="fas fa-sign-out-alt"></i> Cerrar Sesión</a>
      </div>
    </div>
  </nav>

  <div class="container">
    <?php if (!isset($_SESSION['usuario_id'])): ?>
      <!-- Formulario de Login -->
      <div class="row justify-content-center">
        <div class="col-md-4">
          <div class="card bg-light text-dark">
            <div class="card-body">
              <?php if ($mensaje): ?>
                <div class="alert alert-danger text-center"><?= htmlspecialchars($mensaje) ?></div>
              <?php endif; ?>
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
                <button type="submit" class="btn btn-primary w-100"><i class="fas fa-sign-in-alt"></i> Iniciar Sesión</button>
              </form>
            </div>
          </div>
        </div>
      </div>
    <?php else: ?>
      <!-- Dashboard -->
      <h4 class="text-center mb-4">Bienvenido, <?= htmlspecialchars($_SESSION['usuario_nombre']) ?></h4>
      <div class="row">
        <!-- Recursos -->
        <div class="col-md-4">
          <div class="card bg-secondary text-white">
            <div class="card-header"><i class="fas fa-coins"></i> Recursos</div>
            <div class="card-body">
              <?php if ($partida): ?>
                <p class="resource"><i class="fas fa-tree"></i> Madera: <?= $partida['Madera'] ?></p>
                <p class="resource"><i class="fa-solid fa-trowel"></i> Ladrillo: <?= $partida['Ladrillo'] ?></p>
                <p class="resource"><i class="fas fa-coins"></i> Oro: <?= $partida['Oro'] ?></p>
              <?php endif; ?>
            </div>
          </div>
        </div>
        <!-- Infraestructura -->
        <div class="col-md-4">
          <div class="card bg-secondary text-white">
            <div class="card-header"><i class="fas fa-home"></i> Infraestructura</div>
            <div class="card-body">
              <?php if ($partida): ?>
                <p class="resource">Casas: <?= $partida['Numero_Casas'] ?></p>
              <?php endif; ?>
            </div>
          </div>
        </div>
        <!-- Acciones Rápidas -->
        <div class="col-md-4">
          <div class="card bg-secondary text-white">
            <div class="card-header"><i class="fas fa-tools"></i> Acciones Rápidas</div>
            <div class="card-body text-center">
              <!-- Construir Casa / Reclutar Aldeano -->
              <form method="POST" class="d-inline">
                <input type="hidden" name="action" value="construirCasa">
                <button type="submit" class="btn btn-warning mb-2"><i class="fas fa-building"></i> Construir Casa</button>
              </form>
              <form method="POST" class="d-inline">
                <input type="hidden" name="action" value="reclutarAldeano">
                <button type="submit" class="btn btn-info mb-2"><i class="fas fa-user-plus"></i> Reclutar Aldeano</button>
              </form>
              <!-- Mejorar Campamentos -->
              <div class="mb-2">
                <form method="POST" class="d-inline">
                  <input type="hidden" name="action" value="subirCampMadera">
                  <button type="submit" class="btn btn-success"><i class="fas fa-level-up-alt"></i> Subir Camp. Madera</button>
                </form>
                <form method="POST" class="d-inline">
                  <input type="hidden" name="action" value="subirCampLadrillo">
                  <button type="submit" class="btn btn-success"><i class="fa-solid fa-trowel"></i> Subir Camp. Ladrillo</button>
                </form>
                <form method="POST" class="d-inline">
                  <input type="hidden" name="action" value="subirCampOro">
                  <button type="submit" class="btn btn-success"><i class="fas fa-level-up-alt"></i> Subir Camp. Oro</button>
                </form>
              </div>
              <!-- Crear Campamento -->
              <div class="mt-2">
                <form method="POST" class="d-inline">
                  <select name="tipoCamp" class="form-select d-inline w-auto me-2" required>
                    <option value="">-- Tipo Camp. --</option>
                    <option value="Madera">Madera</option>
                    <option value="Ladrillo">Ladrillo</option>
                    <option value="Oro">Oro</option>
                  </select>
                  <input type="hidden" name="action" value="crearCampamento">
                  <button type="submit" class="btn btn-primary"><i class="fas fa-plus-circle"></i> Crear Campamento</button>
                </form>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Sección Mis Campamentos -->
      <div class="row mt-4">
        <div class="col-12">
          <h5 class="text-center text-white mb-3"><i class="fas fa-warehouse"></i> Mis Campamentos</h5>
          <div class="row">
            <?php if (!empty($campamentos)): ?>
              <?php foreach ($campamentos as $camp): ?>
                <div class="col-md-4 mb-3">
                  <div class="card bg-light text-dark">
                    <div class="card-header">
                      <?php 
                        if($camp['Tipo'] === 'Madera'){
                          echo '<i class="fas fa-tree"></i> Campamento de Madera';
                        } elseif($camp['Tipo'] === 'Ladrillo'){
                          echo '<i class="fa-solid fa-trowel"></i> Campamento de Ladrillo';
                        } elseif($camp['Tipo'] === 'Oro'){
                          echo '<i class="fas fa-coins"></i> Campamento de Oro';
                        }
                      ?>
                    </div>
                    <div class="card-body">
                      <p><strong>Nivel:</strong> <?= $camp['Nivel'] ?></p>
                      <p><strong>Trabajadores:</strong> <?= $camp['N_Trabajadores'] ?></p>
                      <?php 
                      // Consultar precio de mejora para el siguiente nivel
                      $stmt2 = $pdo->prepare("SELECT * FROM DATOS_CAMPAMENTOS WHERE Tipo = :t AND Nivel = :n LIMIT 1");
                      $stmt2->execute([':t' => $camp['Tipo'], ':n' => $camp['Nivel'] + 1]);
                      $mejora = $stmt2->fetch(PDO::FETCH_ASSOC);
                      if ($mejora):
                        if($camp['Tipo'] === 'Oro'):
                          echo '<p><strong>Mejora:</strong> Oro = ' . $mejora['Coste_Oro_Mejora'] . '</p>';
                        else:
                          echo '<p><strong>Mejora:</strong> Madera = ' . $mejora['Coste_Madera_Mejora'] . ', Ladrillo = ' . $mejora['Coste_Ladrillo_Mejora'] . '</p>';
                        endif;
                      else:
                        echo '<p><em>Nivel máximo</em></p>';
                      endif;
                      ?>
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
      </div>

      <!-- Sección Asignar/Reasignar Aldeano a Campamento -->
      <div class="row mt-4">
        <div class="col-md-6">
          <div class="card bg-light text-dark">
            <div class="card-header"><i class="fas fa-user-edit"></i> Asignar/Reasignar Aldeano</div>
            <div class="card-body">
              <form method="POST" class="row g-3">
                <div class="col-sm-6">
                  <label class="form-label"><i class="fas fa-id-badge"></i> Seleccionar Aldeano</label>
                  <select name="aldeanoId" class="form-select" required>
                    <option value="">-- Escoge un aldeano --</option>
                    <?php foreach ($aldeanosDisponibles as $ald): ?>
                      <option value="<?= $ald['Id_Aldeanos'] ?>">Aldeano #<?= $ald['Id_Aldeanos'] ?></option>
                    <?php endforeach; ?>
                  </select>
                </div>
                <div class="col-sm-6">
                  <label class="form-label"><i class="fas fa-warehouse"></i> Seleccionar Campamento</label>
                  <select name="campamentoId" class="form-select" required>
                    <option value="">-- Escoge un campamento --</option>
                    <?php foreach ($campamentos as $camp): ?>
                      <option value="<?= $camp['Id_Campamentos'] ?>">
                        <?php 
                          if($camp['Tipo'] === 'Madera'){
                            echo 'Camp. Madera (#' . $camp['Id_Campamentos'] . ')';
                          } elseif($camp['Tipo'] === 'Ladrillo'){
                            echo 'Camp. Ladrillo (#' . $camp['Id_Campamentos'] . ')';
                          } elseif($camp['Tipo'] === 'Oro'){
                            echo 'Camp. Oro (#' . $camp['Id_Campamentos'] . ')';
                          }
                        ?>
                      </option>
                    <?php endforeach; ?>
                  </select>
                </div>
                <input type="hidden" name="action" value="asignarAldeano">
                <div class="col-12 text-end">
                  <button type="submit" class="btn btn-primary"><i class="fas fa-paper-plane"></i> Asignar</button>
                </div>
              </form>
            </div>
          </div>
        </div>
        <!-- Panel de Debug -->
        <div class="col-md-6">
          <div class="card bg-dark text-white" id="debugPanel">
            <div class="card-header"><i class="fas fa-bug"></i> Debug Info</div>
            <div class="card-body">
              <pre><?= htmlspecialchars($debugInfo) ?></pre>
            </div>
          </div>
        </div>
      </div>

      <!-- Sección Mis Aldeanos -->
      <div class="row mt-4">
        <div class="col-12">
          <h5 class="text-center text-white mb-3"><i class="fas fa-users"></i> Mis Aldeanos</h5>
          <?php
            $stmt = $pdo->prepare("SELECT * FROM ALDEANOS WHERE Id_Partida = :p");
            $stmt->execute([':p' => $partida['Id_Partida']]);
            $aldeanos = $stmt->fetchAll(PDO::FETCH_ASSOC);
          ?>
          <div class="row">
            <?php if (!empty($aldeanos)): ?>
              <?php foreach ($aldeanos as $ald): ?>
                <div class="col-md-3 mb-3">
                  <div class="card bg-light text-dark">
                    <div class="card-header">
                      Aldeano #<?= $ald['Id_Aldeanos'] ?>
                    </div>
                    <div class="card-body">
                      <p><strong>Estado:</strong> <?= htmlspecialchars($ald['Estado']) ?></p>
                      <?php if (!empty($ald['Id_Campamentos'])): ?>
                        <p><strong>Camp.:</strong> #<?= htmlspecialchars($ald['Id_Campamentos']) ?></p>
                        <p><strong>Tiempo asignado:</strong> N/A</p>
                      <?php elseif(!empty($ald['Id_Casa'])): ?>
                        <p><strong>Casa:</strong> #<?= htmlspecialchars($ald['Id_Casa']) ?></p>
                      <?php else: ?>
                        <p><strong>No asignado</strong></p>
                      <?php endif; ?>
                      <button class="btn btn-sm btn-outline-primary reasignarBtn" data-ald="<?= $ald['Id_Aldeanos'] ?>">Reasignar</button>
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
                    <option value="">-- Escoge un campamento --</option>
                    <?php foreach ($campamentos as $camp): ?>
                      <option value="<?= $camp['Id_Campamentos'] ?>">
                        <?php 
                          if($camp['Tipo'] === 'Madera'){
                            echo 'Camp. Madera (#' . $camp['Id_Campamentos'] . ')';
                          } elseif($camp['Tipo'] === 'Ladrillo'){
                            echo 'Camp. Ladrillo (#' . $camp['Id_Campamentos'] . ')';
                          } elseif($camp['Tipo'] === 'Oro'){
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

      <!-- Sección Ranking -->
      <div class="row mt-4">
        <div class="col-12">
          <div class="card bg-light text-dark">
            <div class="card-header"><i class="fas fa-trophy"></i> Ranking de Partidas (Completo)</div>
            <div class="card-body">
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
                    <th><i class="fas fa-warehouse"></i> Campamentos</th>
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
                    <td><?= htmlspecialchars($r['TotalCampamentos'] ?? '') ?></td>
                    <td><?= htmlspecialchars($r['TotalAldeanos'] ?? '') ?></td>
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
      </div>
    <?php endif; ?>
  </div>

  <!-- Bootstrap JS -->
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/js/bootstrap.bundle.min.js"></script>
  <!-- Auto-refresco cada 60 segundos -->
  <script>
    setInterval(function() {
      location.reload();
    }, 60000);
  </script>
  <!-- Toggle Debug Panel -->
  <script>
    document.getElementById('btnDebug').addEventListener('click', function() {
      var debugPanel = document.getElementById('debugPanel');
      debugPanel.style.display = (debugPanel.style.display === 'none' || debugPanel.style.display === '') ? 'block' : 'none';
    });
  </script>
  <!-- Script para abrir el modal de reasignación -->
  <script>
    var reasignarBtns = document.querySelectorAll('.reasignarBtn');
    reasignarBtns.forEach(function(btn) {
      btn.addEventListener('click', function() {
        var idAldeano = this.getAttribute('data-ald');
        document.getElementById('modalAldeanoId').value = idAldeano;
        var modal = new bootstrap.Modal(document.getElementById('reasignarModal'));
        modal.show();
      });
    });
  </script>
</body>
</html>
