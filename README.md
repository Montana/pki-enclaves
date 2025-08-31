# tunneling-ngrok-smallstep

this script spins up a local HTTPS server with mutual TLS (mTLS) using Smallstep to generate certificates, and then exposes it securely through ngrok, it creates both HTTP(S) and TCP tunnels, giving you public endpoints to your local service.

# use case 

in theory, the orchestration here is not merely a trivial concatenation of certificate material and tunnel initiation — it’s effectively a pseudo-pki bootstrap environment combined with a reverse-proxied ephemeral ingress fabric. by invoking step certificate create twice (first with `--profile root-ca` and then with `--profile leaf`), you’re establishing an in-situ root of trust, where the root ca is locally sovereign. this self-signed anchor propagates a trust boundary down to the server and client leaf certs, effectively simulating a single-tenant pki enclave.

# client driver `pkcs#12`

when it comes to the second script, the “client driver,” is not a mere curl wrapper, i wanted it to be a consumer of `pkcs#12` keystores. the .p12 container encodes both the client’s private key and its leaf cert, with an optional passphrase (empty here). this artifact mimics what enterprise users might import into a browser truststore or a mutual tls microservice mesh sidecar. its consumption by curl demonstrates client-side cryptographic assertion, binding the transport session cryptographically to the ephemeral pki root.  
