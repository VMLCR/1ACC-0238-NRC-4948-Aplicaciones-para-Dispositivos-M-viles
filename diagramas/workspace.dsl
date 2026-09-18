workspace "PredictiveMaintain" "Propuesta academica: deployment y componentes" {
model {
operator = person "Operador / Tecnico"
manager = person "Jefe de mantenimiento"
sensors = softwareSystem "Sensores IoT" "Origen real o simulado de lecturas"
fcm = softwareSystem "Firebase Cloud Messaging" "Entrega notificaciones"
weather = softwareSystem "Weather API" "Temperatura y humedad por coordenadas, US-29"
email = softwareSystem "Email Service" "Notificaciones y recuperacion de acceso"
system = softwareSystem "PredictiveMaintain" {
mobile = container "Mobile Application" "Consulta activos y atiende ordenes" "Flutter / Dart"
landing = container "Landing Page" "Presentacion del producto" "HTML / CSS / JavaScript"
web = container "Web Management" "Cliente de gestion propuesto" "Angular propuesto"
gateway = container "API Gateway" "Termina TLS y enruta" "Nginx"
broker = container "Event Broker" "Entrega eventos con reintentos" "RabbitMQ propuesto"
files = container "Evidence Storage" "Imagenes de intervenciones" "Volumen persistente"
telemetry = container "Asset Telemetry & Analytics API" "Lecturas, umbrales y resultados analiticos" "NestJS / TypeScript" {
telemetryInterface = component "Telemetry Controllers" "Valida recursos y expone REST" "NestJS controllers"
telemetryApplication = component "Application Handlers" "IngestReadingHandler, EvaluateReadingHandler, ConfigureThresholdHandler, GetAssetAnalyticsHandler" "TypeScript"
telemetryDomain = component "Domain Model" "Sensor, SensorReading, ThresholdRule, AnomalyDetection, RulEstimate" "TypeScript"
telemetryPersistence = component "PostgresTelemetryRepository" "Implementa ITelemetryRepository" "PostgreSQL adapter"
outbox = component "Outbox Publisher" "Publica ThresholdExceeded" "RabbitMQ client"
}
telemetryDb = container "Telemetry Database" "Persistencia exclusiva del contexto" "PostgreSQL"
maintenance = container "Maintenance Operations API" "Activos, alertas, ordenes y evidencias" "NestJS / TypeScript" {
maintenanceInterface = component "Maintenance Controllers" "Valida recursos y expone REST" "NestJS controllers"
maintenanceApplication = component "Application Handlers" "RegisterAssetHandler, RegisterAlertHandler, ConfirmAlertHandler, CreateWorkOrderHandler, DiscardAlertHandler, GetAssetWeatherHandler, AssignWorkOrderHandler, StartWorkOrderHandler, CompleteWorkOrderHandler, SyncOperationsHandler" "TypeScript"
maintenanceDomain = component "Domain Model" "Asset, Alert, WorkOrder, EvidencePhoto, WorkOrderChange" "TypeScript"
maintenancePersistence = component "PostgresMaintenanceRepository" "Implementa IMaintenanceRepository" "PostgreSQL adapter"
consumer = component "Anomaly Consumer + ACL" "Deduplica y traduce eventos" "RabbitMQ client / TypeScript"
integrations = component "Maintenance Adapters" "Capacidad, identidad, fotos y notificaciones" "HTTP / file adapter"
}
maintenanceDb = container "Maintenance Database" "Persistencia exclusiva del contexto" "PostgreSQL"
billing = container "Subscription & Billing API" "Planes, suscripciones y capacidad" "NestJS / TypeScript" {
billingInterface = component "Billing Controllers" "Valida recursos y expone REST" "NestJS controllers"
billingApplication = component "Application Handlers" "RegisterCompanyHandler, ChangeSubscriptionPlanHandler, CheckSubscriptionExpiryHandler, CreateSubscriptionHandler, ReserveCapacityHandler, ConfirmCapacityHandler, ReleaseCapacityHandler, IssueInvoiceHandler" "TypeScript"
billingDomain = component "Domain Model" "Company, SubscriptionPlan, Subscription, CapacityReservation, Invoice" "TypeScript"
billingPersistence = component "PostgresBillingRepository" "Implementa IBillingRepository" "PostgreSQL adapter"
}
billingDb = container "Billing Database" "Persistencia exclusiva del contexto" "PostgreSQL"
iam = container "Identity & Access Management API" "Identidad, autenticacion y roles" "NestJS / TypeScript" {
iamInterface = component "Iam Controllers" "Valida recursos y expone REST" "NestJS controllers"
iamApplication = component "Application Handlers" "RegisterCompanyAccountHandler, RequestPasswordResetHandler, ResetPasswordHandler, UpdateProfileHandler, LoginHandler, CreateUserHandler, ChangeRolesHandler, DeactivateUserHandler, GetUserStatusHandler" "TypeScript"
iamDomain = component "Domain Model" "UserAccount, Role, UserRole, PasswordResetRequest" "TypeScript"
iamPersistence = component "PostgresIamRepository" "Implementa IIamRepository" "PostgreSQL adapter"
security = component "PasswordHashAdapter + JwtTokenAdapter" "Verifica credenciales y emite tokens" "Cryptographic adapters"
}
iamDb = container "Iam Database" "Persistencia exclusiva del contexto" "PostgreSQL"
}
operator -> mobile "Consulta y ejecuta operaciones"
manager -> mobile "Gestiona mantenimiento"
manager -> web "Gestiona operaciones"
manager -> landing "Consulta el producto"
mobile -> gateway "REST" "HTTPS"
web -> gateway "REST" "HTTPS"
sensors -> gateway "Ingesta" "HTTPS"
gateway -> telemetry "Enruta" "HTTP privado"
gateway -> telemetryInterface "Enruta solicitudes REST" "HTTP privado"
telemetryInterface -> telemetryApplication "Invoca casos de uso"
telemetryApplication -> telemetryDomain "Aplica reglas"
telemetryApplication -> telemetryPersistence "Usa puerto de repositorio"
telemetryPersistence -> telemetryDomain "Implementa contrato del dominio"
telemetryPersistence -> telemetryDb "Lee y escribe" "SQL"
gateway -> maintenance "Enruta" "HTTP privado"
gateway -> maintenanceInterface "Enruta solicitudes REST" "HTTP privado"
maintenanceInterface -> maintenanceApplication "Invoca casos de uso"
maintenanceApplication -> maintenanceDomain "Aplica reglas"
maintenanceApplication -> maintenancePersistence "Usa puerto de repositorio"
maintenancePersistence -> maintenanceDomain "Implementa contrato del dominio"
maintenancePersistence -> maintenanceDb "Lee y escribe" "SQL"
gateway -> billing "Enruta" "HTTP privado"
gateway -> billingInterface "Enruta solicitudes REST" "HTTP privado"
billingInterface -> billingApplication "Invoca casos de uso"
billingApplication -> billingDomain "Aplica reglas"
billingApplication -> billingPersistence "Usa puerto de repositorio"
billingPersistence -> billingDomain "Implementa contrato del dominio"
billingPersistence -> billingDb "Lee y escribe" "SQL"
gateway -> iam "Enruta" "HTTP privado"
gateway -> iamInterface "Enruta solicitudes REST" "HTTP privado"
iamInterface -> iamApplication "Invoca casos de uso"
iamApplication -> iamDomain "Aplica reglas"
iamApplication -> iamPersistence "Usa puerto de repositorio"
iamPersistence -> iamDomain "Implementa contrato del dominio"
iamPersistence -> iamDb "Lee y escribe" "SQL"
telemetryApplication -> outbox "Registra evento en transaccion"
outbox -> telemetryDb "Lee outbox pendiente" "SQL"
outbox -> broker "Publica eventos" "AMQP privado"
broker -> consumer "Entrega eventos" "AMQP privado"
consumer -> maintenanceApplication "Traduce y procesa"
integrations -> weather "Consulta clima US-29" "HTTPS"
integrations -> email "Notificaciones EMAIL" "HTTPS"
security -> email "Enlace de recuperacion US-22" "HTTPS"
maintenanceApplication -> integrations "Solicita servicios externos"
integrations -> billing "Reserva / confirma cupo" "HTTP privado"
integrations -> iam "Verifica tecnico" "HTTP privado"
integrations -> files "Guarda / recupera evidencia" "Filesystem privado"
integrations -> fcm "Solicita notificacion" "HTTPS"
fcm -> mobile "Notifica" "Push"
iamApplication -> security "Verifica hash / emite token"
deploymentEnvironment "TB1-Propuesto" {
deploymentNode "Proveedor de clima" "Servicio externo" "HTTPS" {
softwareSystemInstance weather
}
deploymentNode "Proveedor de correo" "Servicio externo" "HTTPS" {
softwareSystemInstance email
}
deploymentNode "Planta industrial" "Origen de mediciones" "Dispositivo IoT" {
softwareSystemInstance sensors
}
deploymentNode "Servicio externo de notificaciones" "Proveedor externo" "Firebase" {
softwareSystemInstance fcm
}
deploymentNode "Dispositivo movil" "Equipo del usuario" "Android" {
containerInstance mobile
}
deploymentNode "Navegador" "Cliente web" "Browser" {
containerInstance web
}
deploymentNode "Hosting estatico" "Proveedor pendiente" "HTTPS" {
containerInstance landing
}
deploymentNode "Servidor de aplicaciones" "Propuesta de una VM para demostracion" "Linux" {
containerInstance gateway
deploymentNode "Red privada" "Acceso interno" "Docker network propuesto" {
containerInstance telemetry
containerInstance maintenance
containerInstance billing
containerInstance iam
containerInstance broker
containerInstance files
}
}
deploymentNode "Servidor PostgreSQL" "No expuesto a Internet" "PostgreSQL" {
containerInstance telemetryDb
containerInstance maintenanceDb
containerInstance billingDb
containerInstance iamDb
}
}
}
views {
deployment system "TB1-Propuesto" "despliegue" {
include *
autoLayout tb
}
component telemetry "telemetry-componentes" {
include *
autoLayout tb
}
component maintenance "maintenance-componentes" {
include *
autoLayout tb
}
component billing "billing-componentes" {
include *
autoLayout tb
}
component iam "iam-componentes" {
include *
autoLayout tb
}
styles {
element "Element" {
background #EAF1F8
color #16324F
}
element "Component" {
background #D8E8F7
}
}
}
}