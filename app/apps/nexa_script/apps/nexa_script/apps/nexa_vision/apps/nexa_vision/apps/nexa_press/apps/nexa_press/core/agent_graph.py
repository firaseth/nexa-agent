from typing import Dict, Any
import uuid
import logging

logger = logging.getLogger(__name__)

class AgentGraph:
    """
    Minimal in-memory agent graph to track agents / tasks and relations.
    Replace with persistent storage or graph DB as needed.
    """
    def __init__(self):
        self.nodes: Dict[str, Dict[str, Any]] = {}

    def add_node(self, metadata: Dict[str, Any]) -> str:
        node_id = str(uuid.uuid4())
        self.nodes[node_id] = metadata
        logger.debug("Added node %s", node_id)
        return node_id

    def get_node(self, node_id: str) -> Dict[str, Any]:
        return self.nodes.get(node_id, {})
