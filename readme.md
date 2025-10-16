
---

##  Despliegue de Servicios Backend y Base de Datos en Kubernetes (K8s)

Este documento describe el proceso de despliegue de los servicios del proyecto dentro de un clúster de **Kubernetes**, incluyendo la **base de datos PostgreSQL** y los **servicios backend**.
Actualmente **no se incluye la parte del frontend**, ya que aún no está preparada para despliegue, la próxima clase lo veremos.

---

## 📂 Estructura del Proyecto

La estructura se organiza siguiendo el **principio de responsabilidad única**, donde cada servicio (backend o base de datos) tiene su propio directorio y manifiestos YAML independientes.  SWYW es el nombre del proyecto en este ejemplo, tu utiliza el que quieras.

```bash
.
├── k8s-swyw-backend/
│   ├── deployment.yaml
│   ├── ns.yaml
│   ├── secrets.yml
│   └── service.yaml
│
└── k8s-swyw-bd/
    ├── ns.yml
    ├── postgres-pv.yml
    ├── postgres-pvc.yml
    ├── postgres-secret.yml
    ├── postgres-stateful.yml
    └── service.yaml
```

> 👁️ OJO!!!: Cada carpeta representa un servicio independiente con sus propios recursos, lo que permite escalar, mantener y actualizar cada uno sin afectar al resto.

---

##  Despliegue de la Base de Datos (PostgreSQL)

### 1. Crear los recursos en orden

El orden **es secuencial de arriba hacia abajo**.
Ejecutar los siguientes comandos desde el directorio `k8s-swyw-bd` (sigue el paso a paso y evitate dolores de cabeza, por favor):

```bash
kubectl apply -f ns.yml
kubectl apply -f postgres-secret.yml
kubectl apply -f postgres-pv.yml
kubectl apply -f postgres-pvc.yml
kubectl apply -f postgres-stateful.yml
kubectl apply -f service.yaml
```

### 2. Verificar que los recursos estén activos

```bash
kubectl get all -n postgres
```

Deberías ver un **StatefulSet** y un **Service** tipo `ClusterIP` en ejecución.

---

### 🧹 Eliminación de recursos (en caso de error o actualización)

Es **importante eliminar en orden inverso** (de abajo hacia arriba) para evitar conflictos de volúmenes o referencias persistentes (no seas terco, hazlo así porque unos utilizan a otros, ya lo hice como 20 veces):

```bash
kubectl delete -f service.yaml
kubectl delete -f postgres-stateful.yml
kubectl delete -f postgres-pvc.yml
kubectl delete -f postgres-pv.yml
kubectl delete -f postgres-secret.yml
```

Luego eliminar manualmente los PVC residuales:

```bash
kubectl get pvc -A
kubectl delete pvc postgres-pvc-postgres-0 -n postgres
```

> ⚠️ **IMPORTANTE:** Si no eliminas los PVC, podrías tener problemas en el siguiente despliegue debido a volúmenes bloqueados.

---

## ⚙️ Despliegue del Backend

Ejecutar los comandos **en el orden indicado** desde el directorio `k8s-swyw-backend`:

```bash
kubectl apply -f ns.yaml
kubectl apply -f secrets.yml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

Verificar los pods y el estado del namespace:

```bash
kubectl get pods -n swyw
```

Salida esperada:

```
NAME                               READY   STATUS              RESTARTS   AGE
swyw-deployment-6c8fd68b75-nxfbp   1/1     Running             0          2s
swyw-deployment-6c8fd68b75-wq4rd   0/1     ContainerCreating   0          2s
```

---

###  Eliminación del backend

En caso de necesitar reiniciar o modificar el despliegue:

```bash
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
kubectl delete -f secrets.yml
```

Verifica que el namespace quede vacío:

```bash
kubectl get all -n swyw
# Salida esperada:
# No resources found in swyw namespace.
```

---

##  Conexión entre Backend y Base de Datos u otro servcio

Dentro de Kubernetes, los servicios se resuelven mediante **DNS interno** con el formato:

```
<service>.<namespace>.svc.cluster.local
```

Para nuestra base de datos PostgreSQL:

```bash
postgres.postgres.svc.cluster.local
```

Por tanto, en los **Secrets del backend** la variable de entorno `DB_HOST_AUTH` debe apuntar a:

```yaml
DB_HOST_AUTH: "postgres.postgres.svc.cluster.local"
```

---

## 🔍 Verificación de conexión desde el pod de la base de datos

Podemos ingresar al contenedor de PostgreSQL y comprobar la resolución DNS interna:

```bash
kubectl exec -it postgres-0 -n postgres -- sh
apt update -y && apt install dnsutils -y
nslookup postgres.postgres.svc.cluster.local
```

Salida esperada (ejemplo):

```
Server:  10.152.183.10
Address: 10.152.183.10#53

Name:    postgres.postgres.svc.cluster.local
Address: 10.152.183.111
```

Esto confirma que el **DNS interno del clúster funciona correctamente** y que el backend puede conectarse al servicio PostgreSQL.

---

## Notas de seguridad a corregir

* Actualmente los **Secrets** están definidos en archivos YAML (`secrets.yml` y `postgres-secret.yml`).
* La idea es reemplazar por una herramienta más segura, como  **HashiCorp Vault**.
* **Nunca** se deben versionar archivos YAML con credenciales reales.

---

##  namespaces y servicios (ejemplo)

| Servicio   | Namespace  | Tipo          | Archivo principal       | Recursos principales          |
| ---------- | ---------- | ------------- | ----------------------- | ----------------------------- |
| PostgreSQL | `postgres` | Base de datos | `postgres-stateful.yml` | PV, PVC, StatefulSet, Service |
| Backend    | `swyw`     | Aplicación    | `deployment.yaml`       | Deployment, Service, Secret   |



## Ejmplo archivos postgres-secret.yml & secrets.yml
> [!NOTE]
> Cabe aclarar que se explican con estos dos archivos, pero en realidad es la misma estructura para todos, solo cambiaria el tema de los metadatos y los valores almacenados

```
#secrets.yml (backend)

apiVersion: v1
kind: Secret
metadata:
  name: backend-secret
  namespace: swyw
type: Opaque
stringData:
  YOUR_KEY=YOUR_VALUE
  YOUR_KEY=YOUR_VALUE
  ...
  +N values
```

```
# postgres-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: postgres
type: Opaque
stringData:
  DB_USER: "some"
  DB_APP_USER_PASSWORD: "some"
  DB_NAME_AUTH: "some"
  DB_PORT: "some"
  DB_USER_DEFAULT: "some"
  DB_ADMIN_PASSWORD: "some"
  POSTGRES_PASSWORD: "some"
  +N values
```

---
