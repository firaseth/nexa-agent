# Nexa: The Autonomous CMO

Nexa is an extensible agent framework designed to orchestrate autonomous marketing workflows:
- campaign planning and outreach (nexa_press)
- vision / media analysis (nexa_vision)
- scripted agent workflows / task engine (nexa_script)

This repository provides starter modules, guardrails and a minimal FastAPI router to run local development.

Quickstart
1. Create a Python venv:
   python -m venv .venv
   source .venv/bin/activate
2. Install dependencies:
   pip install -r requirements.txt
3. Run the API:
   uvicorn app.main:app --reload
4. Run tests:
   pytest -q

Project layout
- apps/
  - nexa_script: core agent engine and scripts
  - nexa_vision: FastAPI router for vision features
  - nexa_press: outreach/campaign helpers
- core/: shared agent graph and guardrails
- docs/: brand guide and strategy templates
- .github/workflows/: CI

Contributing
- Open an issue or PR for new features.
- Follow the code style and add tests for new functionality.

License
MIT (see LICENSE)
