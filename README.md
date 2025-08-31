# tunneling-ngrok-smallstep

this script spins up a local HTTPS server with mutual TLS (mTLS) using Smallstep to generate certificates, and then exposes it securely through ngrok, it creates both HTTP(S) and TCP tunnels, giving you public endpoints to your local service.

# use case 

in theory, the orchestration here is not merely a trivial concatenation of certificate material and tunnel initiation — it’s effectively a pseudo-pki bootstrap environment combined with a reverse-proxied ephemeral ingress fabric. by invoking step certificate create twice (first with `--profile root-ca` and then with `--profile leaf`), you’re establishing an in-situ root of trust, where the root ca is locally sovereign. this self-signed anchor propagates a trust boundary down to the server and client leaf certs, effectively simulating a single-tenant pki enclave.
