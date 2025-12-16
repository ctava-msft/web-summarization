#!/usr/bin/env python3
"""
Web Summarization with Bing Grounding and GPT-5.2-chat

This script uses Azure AI Foundry Projects Agents with Bing Grounding
to search the web and summarize results with GPT-5.2-chat.
"""

import os
import sys
from dotenv import load_dotenv
from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import (
    PromptAgentDefinition,
    BingGroundingAgentTool,
    BingGroundingSearchToolParameters,
    BingGroundingSearchConfiguration,
)
from azure.identity import DefaultAzureCredential

# Load environment variables
load_dotenv()

def search_and_summarize(query: str) -> str:
    """
    Use Azure AI Foundry Projects Agents with Bing Grounding to search and summarize
    
    Args:
        query: Search query string
        
    Returns:
        Summary of search results
    """
    # Get environment variables
    project_endpoint = os.getenv("AZURE_AI_PROJECT_ENDPOINT")
    deployment = os.getenv("AZURE_AI_MODEL_DEPLOYMENT_NAME", "gpt-5.2-chat")
    bing_conn_id = os.getenv("BING_PROJECT_CONNECTION_ID")
    
    print(f"Project Endpoint: {project_endpoint}")
    print(f"Model Deployment: {deployment}")
    print(f"Bing Connection ID: {bing_conn_id}")
    
    # Create AI Project Client
    project_client = AIProjectClient(
        endpoint=project_endpoint,
        credential=DefaultAzureCredential()
    )
    
    # Get OpenAI client for responses
    openai_client = project_client.get_openai_client()
    
    print(f"\nSearching and summarizing: {query}\n")
    
    # Create agent with Bing grounding tool using versioning API
    with project_client:
        agent = project_client.agents.create_version(
            agent_name="WebResearcher",
            definition=PromptAgentDefinition(
                model=deployment,
                instructions="You are a helpful research assistant. Use Bing search to find current information and provide a comprehensive summary.",
                tools=[
                    BingGroundingAgentTool(
                        bing_grounding=BingGroundingSearchToolParameters(
                            search_configurations=[
                                BingGroundingSearchConfiguration(
                                    project_connection_id=bing_conn_id
                                )
                            ]
                        )
                    )
                ],
            ),
            description="Web research assistant with Bing grounding",
        )
        print(f"Agent created (id: {agent.id}, name: {agent.name}, version: {agent.version})")
        
        # Send request using streaming
        print("Agent is researching...")
        stream_response = openai_client.responses.create(
            stream=True,
            input=query,
            extra_body={"agent": {"name": agent.name, "type": "agent_reference"}},
        )
        
        result_text = ""
        citations = []
        
        # Process the streaming response
        for event in stream_response:
            if event.type == "response.created":
                print(f"Response created with ID: {event.response.id}")
            elif event.type == "response.output_text.delta":
                print(event.delta, end="", flush=True)
                result_text += event.delta
            elif event.type == "response.output_text.done":
                print("\n\nResponse done!")
            elif event.type == "response.output_item.done":
                if event.item.type == "message":
                    item = event.item
                    if item.content and len(item.content) > 0 and item.content[-1].type == "output_text":
                        text_content = item.content[-1]
                        if hasattr(text_content, 'annotations'):
                            for annotation in text_content.annotations:
                                if annotation.type == "url_citation":
                                    citations.append(f"  - {annotation.url}")
            elif event.type == "response.completed":
                print("Response completed!")
        
        # Print citations
        if citations:
            print("\nCitations:")
            for citation in citations:
                print(citation)
        
        # Clean up resources by deleting the agent version
        print("\nCleaning up resources...")
        project_client.agents.delete_version(agent.name, agent.version)
        print("Agent deleted")
        
        return result_text if result_text else "No response generated"


def main():
    """Main function to run web search and summarization"""
    
    # Default query about Oklahoma City Thunder game
    query = "who won the Oklahoma City thunder game on 12/2/2025?"
    
    # Allow command line argument to override
    if len(sys.argv) > 1:
        query = sys.argv[1]
    
    print("=" * 80)
    print("Web Summarization with Bing Grounding and GPT-5.2-chat")
    print("=" * 80)
    print(f"Query: {query}")
    print("=" * 80)
    
    try:
        # Execute search and summarization
        result = search_and_summarize(query)
        
        # Display summary
        print("\n" + "=" * 80)
        print("SUMMARY")
        print("=" * 80)
        print(f"\n{result}\n")
        print("=" * 80)
        
        print("\n✅ Processing complete!")
        return 0
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    exit(main())
