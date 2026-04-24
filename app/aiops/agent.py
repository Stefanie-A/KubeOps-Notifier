"""
AIOps agent — uses LangChain + OpenRouter to investigate a Kubernetes
incident and return an enriched RCA with remediation steps.
"""

import os
import logging
from dataclasses import dataclass

from langchain_openai import ChatOpenAI
from langchain.agents import AgentExecutor, create_tool_calling_agent
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder

from .tools import (
    describe_pod,
    get_pod_logs,
    query_prometheus,
    query_loki_logs,
    list_recent_events,
)

log = logging.getLogger("kubeops-notifier.aiops.agent")

OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1"
OPENROUTER_MODEL    = os.getenv("OPENROUTER_MODEL", "mistralai/mistral-7b-instruct:free")

SYSTEM_PROMPT = """You are KubeOps AI, an expert Kubernetes SRE assistant.
When given an incident alert you MUST:
1. Use the available tools to gather evidence (pod state, logs, metrics, events).
2. Identify the most likely root cause based on evidence — not assumptions.
3. Provide a concise, structured response in this exact format:

*Root Cause:* <one sentence>
*Evidence:*
- <key finding 1>
- <key finding 2>
*Remediation:*
1. <immediate action>
2. <follow-up action>
*Severity:* <Critical | High | Medium | Low>

Be concise. Do not repeat raw tool output in your final answer."""


@dataclass
class IncidentContext:
    namespace: str
    reason: str
    kind: str
    name: str
    message: str


def build_agent() -> AgentExecutor:
    llm = ChatOpenAI(
        model=OPENROUTER_MODEL,
        openai_api_key=os.environ["OPENROUTER_API_KEY"],
        openai_api_base=OPENROUTER_BASE_URL,
        temperature=0,
        max_tokens=1024,
    )

    tools = [
        describe_pod,
        get_pod_logs,
        query_prometheus,
        query_loki_logs,
        list_recent_events,
    ]

    prompt = ChatPromptTemplate.from_messages([
        ("system", SYSTEM_PROMPT),
        ("human", "{input}"),
        MessagesPlaceholder(variable_name="agent_scratchpad"),
    ])

    agent = create_tool_calling_agent(llm, tools, prompt)
    return AgentExecutor(agent=agent, tools=tools, verbose=False, max_iterations=6)


# Singleton — built once at startup
_executor: AgentExecutor | None = None


def get_executor() -> AgentExecutor:
    global _executor
    if _executor is None:
        _executor = build_agent()
    return _executor


def analyze_incident(ctx: IncidentContext) -> str:
    """
    Run the AIOps agent against an incident context.
    Returns the enriched RCA string to be sent to Slack.
    """
    query = (
        f"Incident detected in namespace `{ctx.namespace}`.\n"
        f"Reason: {ctx.reason}\n"
        f"Affected object: {ctx.kind}/{ctx.name}\n"
        f"Event message: {ctx.message}\n\n"
        f"Investigate this incident using available tools and provide a root cause analysis."
    )
    try:
        result = get_executor().invoke({"input": query})
        return result["output"]
    except Exception as e:
        log.error("AIOps agent failed: %s", e)
        return f"_(AIOps analysis unavailable: {e})_"
