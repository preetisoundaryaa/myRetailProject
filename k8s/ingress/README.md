# Local Ingress Notes

The active myRetail ingress is rendered from `helm/myretail/templates/ingress.yaml` and is managed by Argo CD.

For Docker Desktop Kubernetes, add this host entry before browsing the app:

```text
127.0.0.1 myretail.local
```

Then open:

```text
http://myretail.local
```

TLS is intentionally omitted for the local demo. In production, terminate TLS with cert-manager and a real DNS name.
