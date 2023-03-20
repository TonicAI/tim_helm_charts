# Tonic TIM Chart

TIM is a web UI for configuring, installing and managing the Tonic application.

## Necessary Parameters

These are the only parameters _necessary_ to provide to install Tim.

| Name | Description | Type |
| ---- | ---- | ---- |
| web.configuration.database.username | Postgres username for TIM to use | string |
| web.configuration.database.password | Password for postgres user | string |
| web.configuration.database.database | Postgres database name for TIM to use | string |
| web.configuration.database.host | Postgres host for TIM to connect to | string |

Alternatively, a secret may be created with the following fields:

* TIM_DB_USERNAME
* TIM_DB_PASSWORD

If such a secret is created, then `web.configuration.database.secretName` should be
provided instead of the individual values for username and password.

Additionally, either `global.tonicPullSecret` or `global.pullSecrets` may be
necessary to provide based on how images are pulled into your cluster. If in
doubt, set `global.tonicPullSecret` to the value provided to you by your Tonic
representative.

Finally, a RSA AES-256 keypair should be generated and the _PUBLIC_ key
provided as `web.configuration.masterCert.publicKey`. The accompanying private
key should be generated with a password that is SHA256 hashed to ensure proper
key length. This key pair is used to provided administrative access to TIM.

A minimal values would look like:

```yaml
global:
  tonicPullSecret:
    name: tonic-quay
    value: <...>

web:
  configuration:
    database:
      username: tim
      password: password
      host: db.example.com
      database: tim
    masterCert:
      publicKey: "<base64>"
```

With the above configuration, this chart will successfully install the default
image of:

```
quay.io/tonicai/timothy:latest
```

## Global Parameters

| Name | Description | Default | Type |
| ---- | ---- | ---- | ---- |
| global.rbac.create | Set to "false" to disable RBAC creation in the entire chart | true | Boolean |
| global.annotations | Annotations to apply to every resource | {} | {string: string} |
| global.pullSecrets | Pull secrets to apply to every pod. Use this if you pull all images from a proxy or internal registry and need authorization | [] | PullSecret[] |
| global.tonicPullSecret | Pull secret to pull Tonic provided images. | {} | PullSecret |
| global.alternativeRepository | Overrides repository for all images. Use this if you pull all images from a proxy or internal registry. | "" | string |
| global.pullPolicy | Default pull policy to use for _all_ images. See kubernetes documentation for accepted values.| "IfNotPresent" | "" | string |

### PullSecret

Pull secrets can provided with or without their value. If a value is not
provided, then it is considered an existing external secret and will only be
attached to pods. If a value is provided, then the pull secret is created
before attaching to pods.

```yaml
- name: ExistingSecret
- name: NewSecret
  value: "base64 encoded value"
```

## TIM Configuration Parameters

| Name | Description | Default | Type |
| ---- | ---- | ---- | ---- |
| web.configuration.env | Environment variables to set directly onto the TIM pod | null | {string: string} |
| web.configuration.envRaw | The contents of this block are dropped directly into the environment variables for TIM. Use this to load an environment variable from a ConfigMap or Secret | null | {string: any} |
| web.configuration.database.secretName | Provide this if you have an existing kubernetes secret with the necessary fields for TIM to connect to its database | "" | string |
| web.configuration.database.username | Postgres username for TIM to use | "" | string |
| web.configuration.database.password | Password for postgres user | "" | string |
| web.configuration.database.database | Postgres database name for TIM to use | "" | string |
| web.configuration.database.host | Postgres host for TIM to connect to | "" | string |
| web.configuration.database.port | Postgres port for TIM to connect to | "5432" | string |
| web.configuration.database.sslMode | SSL mode to use to when connecting to the postgres instance. [See here for details](https://www.npgsql.org/doc/security.html#encryption-ssltls) | Prefer | string |
| web.configuration.encryption.value | Secret key TIM uses for encryption | "" | string |
| web.configuration.encryption.secretName | Existing secret to be mounted for providing the encryption key. Disregards the encryption.value | "" | string |

Example:

```yaml
web:
  configuration:
    env:
      SOME_ENVVAR: "value"
    envRaw:
      FROM_CONFIGMAP:
        valueFrom:
          configMapRef:
            name: existing-config-map
            key: specific.value

    database:
      username: postgres
      password: postgres
      database: postgres
      port: "5432"
      sslMode: Require
      host: postgres.svc

    encryption:
      value: "it's a secret to everyone"
```

To provide database or encryption details from existing secrets:

```yaml
web:
  configuration:
    database:
      secretName: existing-secret-db
    encryption:
      secretName: existing-secret-encrypt
```

Providing `secretName` for either `database` or `encryption` causes this chart to
not create its own secrets even if values are provided for that. When providing
`secretName` ensure the secret exists within the same namespace that TIM is
being deployed to otherwise the container will not start.

## Volume

| Name | Description | Default | Type |
| ---- | ---- | ---- | ---- |
| web.volumes | Volumes to mount to the TIM container | [] | Volume[] |

Volumes are provided in the following format:

```yaml
web:
  volumes:
    - name: Pod specific name for volume
      path: Mount path inside the container
      details: Specific to each mount type
```

For example, to mount an `emptyDir` at `/var/log/tim` you would provide the
following:

```yaml
web:
  volumes:
    - name: log-mount
      path: /var/log/tim
      details:
        emptyDir: {}
```

To mount a persistent volume Claim at `/etc/tim/example` you would provide the
following:

```yaml
web:
  volumes:
    - name: example-mount
      path: /etc/tim/example
      details:
        persistentVolumeClaim:
          claimName: my-claim
```

## Resources

| Name | Description | Default | Type |
| ---- | ---- | ---- | ---- |
| web.resources.requests | Resource requests for TIM | { cpu: 100m, memory: 256Mi } | Kubernetes resource request |
| web.resources.limits | Resource limits to impose on TIM | { memory: 1Gi } | Kubernetes resource limit |

These resources are applied to the TIM container. For details on resources, [see the kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/).

## Service Accounts and RBAC

| Name | Description | Default | Type |
| ---- | ---- | ---- | ---- |
| web.serviceAccount.create | Controls if a service account for _TIM_ is created | true | boolean |
| web.serviceAccount.rbac.create | Controls if this chart creates RBAC resources needed for _TIM_ | true | boolean |
| installJob.serviceAccount.rbac.create | Controls if this chart create RBAC resources needed for the _TIM worker_ | true | boolean |
| installJob.serviceAccount.rbac.clusterRoleName | The cluster role that should be assigned to the  _TIM worker_ | "timothy-install-job" | string |

For RBAC needs, consult [the TIM documentation](#rbac).

## Image
These settings are found under web.image and installJob.image.
| Name | Description | Default | Type |
| ---- | ---- | ---- | ---- |
| name | Image name to pull. Only set this if you are pulling an from alternative image repository that does not container the default image name. | "tonicai/timothy" | string |
| repo | Image repository to pull from. Only set this if you are pulling from an alternative image repository not provided by Tonic | "quay.io" | string |
| tag | Image tag to pull.  | "latest" | string |
| pullPolicy | Pull policy specific to TIM. Overrides `global.pullPolicy` if provided | "IfNotPresent" | string |

## Networking

| Name | Description | Default | Type |
| ---- | ---- | ---- | ---- |
| networking.service.type | Controls which type of kubernetes service is created | "ClusterIP" | string |
| networking.service.annotations | Annotations to apply specific to the service resource | {} | {string: string} |
| networking.https.enabled | Controls if TIM binds to a port for HTTPS | false | boolean |
| networking.https.useBundledCerts | Determines if TIM should use its bundled certificates for HTTPS or not | true | boolean |
| networking.https.certSecretName | If set and `useBundledCerts` is false, then causes TIM to use the mentioned secret to for its certificates | "" | string |
| networking.http.enabled | Controls if TIM binds to a port for HTTP | true | boolean |

If _both_ networking.http.enabled and networking.https.enabled are set to
false, the chart issues an error and refuses to deploy. At least one must be
enabled.

Enabling https via these settings allows the TIM pod and service to receive
HTTPS connections directly. If you are using an ingress and want to terminate
HTTPS at the ingress level, see the [Ingress](#Ingress) section to configure
TLS certificates.

### Ingress

NOTE: All field names are prefixed with `networking.ingress`, it is omitted
here for readability.

| Name | Description | Default | Type |
| ---- | ---- | ---- | ---- |
| enabled | Controls if this chart should create an ingress for TIM | false | boolean |
| className | Ingress class to use. Must be provided when creating an ingress. | "" | string |
| portName | Set this to explicitly override which port the ingress will point at | "" | string |
| annotations | Annotations to apply specifically to the ingress resource | {} | {string: string} |
| hosts | Hosts and their paths to declare on the ingress | [] | IngressRule[] |
| hosts.host | The domain name or IP to bind the host to.  Set to `null` to bind to all ingress | "" | string |
| tls | TLS configuration for ingress | [] | IngressTLS[] |

For details on IngressRule and IngressTLS, [consult the kubernetes
documentation](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

When TIM creates the ingress it will prefer HTTP as the backend port unless
that is disabled. If you want to enable HTTPS from the ingress to TIM while
still exposing the HTTP port, set `networking.ingress.portName` to `https`. Be
sure to consult your ingress's documentation for any annotations that may be
needed for this configuration to work. For example, if you are using the
nginx-ingress, you would need to add
`nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"` to the ingress
annotations.

The TLS certificates referenced in the ingress section are separate from the
TLS certificates used by this chart to enable TLS on the TIM pod itself and are
not created by this chart.

Example configuration of using end-to-end TLS with custom certificates for both
TIM and the ingress:

```yaml
networking:
  https:
    enabled: true
    useBundledCerts: false
    certSecretName: "example-certificates"
  http:
    enabled: false
  ingress:
    enabled: true
    className: "nginx"
    annotations:
      nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    hosts:
      - host: tim.example.com
        paths:
          - path: "/"
            pathType: "ImplementationSpecific"
    tls:
      - secretName: tim-example-tls
        hosts:
          - tim.example.com
```

Since the HTTP port is disabled, this chart will automatically point the
ingress at the HTTPS port.

## Other

| Name | Description | Default | Type |
| ---- | ---- | ---- | ---- |
| web.annotations | Annotations to apply specifically to the TIM pod | {} | {string: string} |
