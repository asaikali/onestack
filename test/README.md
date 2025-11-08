#  Example Cluster Bootstrap

This directory provides a **self-contained example** of how a cluster consumes the
[`onestack`](https://github.com/asaikali/onestack) *platform BOM*.

It simulates what a real cluster repository (for example, `acme-inc-cluster`) would do
when installing the platform.

## Purpose

- Validate that the platform BOM (`onestack/platform`) can bootstrap a clean cluster end-to-end.  
- Demonstrate the structure of a consumer cluster repo that uses the platform.  
- Serve as a reference for anyone building their own cluster repo.

##  Layout

```
test/
└── example-cluster/
├── flux-system/
│   ├── gotk-sync.yaml        # tells Flux how to pull the platform
│   └── kustomization.yaml    # aggregates Flux CRDs for this cluster
└── cluster/
├── clusterissuer.yaml    # sample cluster config (uses cert-manager)
├── externalsecret.yaml   # sample ESO secret (uses external-secrets)
└── kustomization.yaml    # waits for the platform to be ready
```

### Directories

| Path | Purpose |
|------|----------|
| `flux-system/` | Contains the Flux objects (`GitRepository`, `Kustomization`) that bootstrap the platform into this cluster. |
| `cluster/` | Contains example cluster-specific resources that depend on the platform (cert-manager, ESO, etc.). |
| `kustomization.yaml` files | Define how Flux layers resources and enforces reconciliation order. |


## How the Bootstrap Works

### 1. Install Flux controllers

You need the Flux controllers running before Flux can reconcile anything.

From the root of the repo:

```bash
kubectl apply -f ../../platform/flux-system/gotk-components.yaml
```

This installs the Flux controllers (source-controller, kustomize-controller, etc.)
into the `flux-system` namespace.


### 2. Apply the example cluster definition

```bash
kubectl apply -f flux-system/
```

This creates two key Flux resources:

1. **GitRepository** – points back to this repo (`onestack`)  
   and checks out the `platform/` directory.
2. **Kustomization** – applies everything under `./platform`
   (Flux, cert-manager, ESO, Envoy Gateway, CNPG, …).

Once the platform layer is reconciled and healthy, Flux
automatically applies the **cluster layer** defined under `cluster/`.

### 3. Observe reconciliation

Check status:

```bash
flux get sources git -A
flux get kustomizations -A
```

You should see:

```
platform          Ready  True   <timestamp>
cluster-config    Ready  True   <timestamp>
```

The `dependsOn` field in `cluster/kustomization.yaml`
ensures the cluster resources wait until the platform
components are healthy (cert-manager, ESO, etc.).

## What You’re Testing

By running this example, you verify that:

- The platform BOM in `onestack/platform` installs cleanly.
- All core operators (Flux, cert-manager, ESO, CNPG, Envoy Gateway) reach a healthy state.
- Cluster-level resources that depend on those operators apply successfully.

This gives confidence that the `onestack` platform tag (e.g., `v1.0.0`) is
a valid, tested release before it’s consumed by real clusters.

## Using This as a Template

When you create a real cluster repo (for example, `acme-inc-cluster`):

1. Copy the contents of `flux-system/` into your own `flux-system/`.
2. Change the Git URL and ref in `gotk-sync.yaml` to pin to a specific platform version:

   ```yaml
   ref:
     tag: v1.0.0
   ```

3. Replace `cluster/` with your own cluster-specific configuration
   (issuers, secrets, namespaces, apps).

Your repo then manages itself exactly like this example, but with your own data.

## Cleanup

To remove everything from your test cluster:

```bash
flux uninstall --namespace flux-system
kubectl delete ns flux-system --ignore-not-found
```

##  Summary

This example demonstrates the complete **Flux bootstrap lifecycle**:

1. Install Flux controllers.
2. Flux pulls and applies the versioned **platform BOM**.
3. Cluster-specific configuration waits for the platform to reconcile.
4. Everything becomes fully declarative and self-managing.

It serves as both a **test harness** for the platform repo and a **reference**
for new cluster repositories.
