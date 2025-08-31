# pki enclaves

this script spins up a local HTTPS server with mutual TLS (mTLS) using Smallstep to generate certificates, and then exposes it securely through ngrok, it creates both HTTP(S) and TCP tunnels, giving you public endpoints to your local service.

## use case 

in theory, the orchestration here is not merely a trivial concatenation of certificate material and tunnel initiation — it’s effectively a pseudo-pki bootstrap environment combined with a reverse-proxied ephemeral ingress fabric. by invoking step certificate create twice (first with `--profile root-ca` and then with `--profile leaf`), you’re establishing an in-situ root of trust, where the root ca is locally sovereign. this self-signed anchor propagates a trust boundary down to the server and client leaf certs, effectively simulating a single-tenant pki enclave.

## client driver `pkcs#12`

when it comes to the second script, the “client driver,” is not a mere curl wrapper, i wanted it to be a consumer of `pkcs#12` keystores. the `.p12 container` encodes both the client’s private key and its leaf cert, with an optional passphrase (empty here). this artifact mimics what enterprise users might import into a browser truststore or a mutual tls microservice mesh sidecar. its consumption by curl demonstrates client-side cryptographic assertion, binding the transport session cryptographically to the ephemeral pki root.  

## pki enclaves and federated tunnel abstractions 

<img width="1983" height="1581" alt="IMG_3358" src="https://github.com/user-attachments/assets/144d5ebb-ab2c-4dbc-881a-fe89126ea9bc" />

once you’ve got your enclave, you expose it not by opening raw ports yourself, but by letting ngrok handle ingress. here’s where the federation angle comes in: ngrok’s http tunnels operate at layer 7 (application-aware proxying), while its tcp tunnels operate at layer 4 (raw transport proxying). the federation is the coexistence of these different abstraction layers under a single umbrella, forwarding traffic into your local enclave. think of it as a federation of tunnel types, bound together into one fabric.

## entropy drain 

every loop iteration calls curl against the ngrok-exposed https endpoint, presenting the client’s `pkcs#12` bundle and verifying against the enclave’s self-issued root. each call forces a full tls handshake cycle: ephemeral key exchange, certificate validation, session key derivation. openssl’s tls machinery draws from the linux kernel’s random number generator (/`dev/urandom` or getrandom) to seed nonces and ephemeral keypairs. the while-true loop in `entropy-drain.sh` pushes this system into continuous demand, effectively bleeding the entropy pool. in cryptographic systems, entropy is a finite, slowly replenishing substrate, in turn causing entropy. 

## docker and pki enclaves 

when considered in the context of this safetunnels construct, docker ceases to be simply a packaging convenience and instead becomes a cryptographic trust amplifier. the image acts as an immutable locus of certificate authority bootstrapping, encapsulating both the smallstep cli and the openssl trust fabric inside a single content-addressed lineage. by doing so, docker guarantees that every instantiation of the container will deterministically re-manifest the same pseudo-sovereign pki enclave, with no dependency drift or host contamination.

<img width="938" height="587" alt="Screenshot 2025-08-30 at 11 15 58 PM" src="https://github.com/user-attachments/assets/a77378f2-613f-426d-a299-7a3b49f26046" />

what's noteworthy to me is the docker build stage materializes an immutable image lineage, a deterministic layering of filesystem diffs that together constitute a hermetic execution fossil. the act of docker run is therefore less a process spawn and more a projection of this fossilized lineage into an isolated namespace context, where pid trees, mount spaces, and network fabrics are carved into existence under cgroups control.

## author
michael mendy (c) 2025
