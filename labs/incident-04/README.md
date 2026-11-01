# Incident 04 — The Network Path Failure

**Optional exercise.** Requests cannot reach the application as expected. The book provides the investigation; this page provides only the controls and safe exit.

**Requires:** Working shared Shop practice environment. Run from the repository root.

```bash
# Check the application before injecting a fault.
scripts/validate-baseline.sh
# Allow lab-only AWS changes.
export CONFIRM_LAB_CHANGES=YES
# Prepare, trigger, and inspect the initial incident state.
scripts/incident.sh 04 setup
scripts/incident.sh 04 inject
scripts/incident.sh 04 status
```

**Stop and investigate:** Use Incident 04 in the book. You can reset safely without completing the investigation.

**Reset and verify:**

```bash
# Remove this incident's controlled change.
scripts/incident.sh 04 reset
# Confirm the Shop works again.
scripts/validate-baseline.sh
```

Requires `iptables-nft` on the EC2 instance; the supplied bootstrap installs it on new instances. Check the SSM command result before relying on it.

