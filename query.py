#!/usr/bin/env python3
"""
Web Summarization with Bing Grounding and GPT

This script uses Azure AI Agent Service to create an agent with Bing Grounding
to search the web and summarize results with GPT-4o.
"""

import os
import json
import sys
from dotenv import load_dotenv
from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential
from azure.ai.projects.models import BingGroundingTool

# Load environment variables
load_dotenv()

def search_and_summarize(query: str) -> str:
    """
    Use Azure AI Agent with Bing Grounding to search and summarize
    
    Args:
        query: Search query string
        
    Returns:
        Summary of search results
    """
    # Get environment variables
    location = os.getenv("AZURE_LOCATION")
    sub = os.getenv("AZURE_SUBSCRIPTION_ID")
    group = os.getenv("AZURE_RESOURCE_GROUP")
    proj = os.getenv("AI_PROJECT_NAME")
    
    print(f"Location: {location}")
    print(f"Subscription: {sub}")
    print(f"Resource Group: {group}")
    print(f"Project: {proj}")
    
    # Create connection string for AI Foundry Project
    ai_project_conn_str = f"{location}.api.azureml.ms;{sub};{group};{proj}"
    print(f"Connection String: {ai_project_conn_str}")
    
    # Create AI Project Client
    project_client = AIProjectClient.from_connection_string(
        credential=DefaultAzureCredential(),
        conn_str=ai_project_conn_str,
    )
    
    # Get Bing connection
    bing_connection = project_client.connections.get(
        connection_name='bing-grounding-connection'
    )
    conn_id = bing_connection.id
    print(f"Bing Connection ID: {conn_id}")
    
    # Initialize Bing Grounding tool
    bing = BingGroundingTool(connection_id=conn_id)
    
    print(f"\nSearching and summarizing: {query}\n")
    
    # Create agent with Bing tool
    with project_client:
        agent = project_client.agents.create_agent(
            model=os.getenv("GPT52_CHAT_DEPLOYMENT_NAME", "gpt-52-chat"),
            name="web-researcher",
            instructions="You are a helpful research assistant. Use Bing search to find current information and provide a comprehensive summary.",
            tools=bing.definitions,
        )
        print(f"Created agent, ID: {agent.id}")
        
        # Create thread for communication
        thread = project_client.agents.create_thread()
        print(f"Created thread, ID: {thread.id}")
        
        # Create message to thread
        message = project_client.agents.create_message(
            thread_id=thread.id,
            role="user",
            content=query,
        )
        print(f"Created message, ID: {message.id}")
        
        # Create and process agent run in thread with tools
        print("Agent is researching...")
        run = project_client.agents.create_and_process_run(
            thread_id=thread.id,
            assistant_id=agent.id
        )
        print(f"Run finished with status: {run.status}")
        
        # Fetch and return messages
        messages = project_client.agents.list_messages(thread_id=thread.id)
        
        # Get the response from the agent
        if messages.data and len(messages.data) > 0:
            response = messages.data[0]['content'][0]['text']['value']
        else:
            response = "No response generated"
        
        # Clean up
        project_client.agents.delete_agent(agent.id)
        print("Agent deleted")
        
        return response


def main():
    """Main function to run web search and summarization"""
    
    # Default query about Microsoft Surface laptops
    query = "Microsoft Surface laptops latest models and features"
    
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
            name="research-assistant",
            instructions="""You are a helpful research assistant. Use the Bing search tool to find current information 
            about the user's query. Provide a comprehensive summary of what you find, including key facts, 
            recent developments, and relevant insights. Always cite your sources.""",
            tools=bing_tool.definitions,
        )
        logger.info(f"Created agent, ID: {agent.id}")
        
        # Create thread for communication
        thread = project_client.agents.create_thread()
        logger.info(f"Created thread, ID: {thread.id}")
        
        # Create message to thread
        message = project_client.agents.create_message(
            thread_id=thread.id,
            role="user",
            content=query,
        )
        logger.info(f"Created message, ID: {message.id}")
        
        # Run the agent
        logger.info("Running agent with Bing Grounding...")
        run = project_client.agents.create_and_process_run(
            thread_id=thread.id,
            assistant_id=agent.id
        )
        logger.info(f"Run finished with status: {run.status}")
        
        # Get run steps to extract search queries and citations
        run_steps = project_client.agents.list_run_steps(
            run_id=run.id,
            thread_id=thread.id
        )
        
        # Extract Bing search tool calls
        search_results = []
        for step in run_steps.get('data', []):
            if step.get('type') == 'tool_calls':
                for tool_call in step.get('step_details', {}).get('tool_calls', []):
                    if tool_call.get('type') == 'bing_grounding':
                        search_results.append(tool_call)
        
        # Get the final response
        messages = project_client.agents.list_messages(thread_id=thread.id)
        
        if messages.data and len(messages.data) > 0:
            response_message = messages.data[0]
            summary = response_message.content[0].text.value
            
            # Extract citations/annotations
            annotations = response_message.content[0].text.annotations if hasattr(response_message.content[0].text, 'annotations') else []
            citations = []
            for annotation in annotations:
                if hasattr(annotation, 'url'):
                    citations.append({
                        'text': annotation.text,
                        'url': annotation.url
                    })
        else:
            summary = "No response generated"
            citations = []
        
        # Clean up
        project_client.agents.delete_agent(agent.id)
        logger.info("Agent deleted")
        
        return {
            'query': query,
            'summary': summary,
            'citations': citations,
            'search_results': search_results
        }

def save_results_to_markdown(result: Dict[str, Any]) -> str:
    """Save query results and summary to a timestamped markdown file"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"bing_results_{timestamp}.md"
    
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(f"# Bing Grounding + GPT-5.2-chat Results\n\n")
        f.write(f"**Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        f.write(f"**Query:** {result['query']}\n\n")
        f.write(f"---\n\n")
        
        f.write(f"## GPT-5.2-chat Summary (with Bing Grounding)\n\n")
        f.write(f"{result['summary']}\n\n")
        
        if result['citations']:
            f.write(f"---\n\n")
            f.write(f"## Citations\n\n")
            for i, citation in enumerate(result['citations'], 1):
                f.write(f"{i}. [{citation.get('text', 'Source')}]({citation['url']})\n")
            f.write(f"\n")
    
    logger.info(f"Results saved to {filename}")
    return filename

def main():
    """Main function to run Bing Grounding with GPT-5.2"""
    
    # Check environment
    if not check_environment():
        return 1
    
    # Query about OKC Thunder
    query = "OKC thunder latest news and lessons to be learned about the loss to the spurs"
    
    logger.info("=" * 80)
    logger.info("GPT-5.2-chat with Bing Grounding (Azure AI Agent Service)")
    logger.info("=" * 80)
    
    try:
        # Execute search with Bing agent
        result = search_with_bing_agent(query)
        
        # Display summary
        print("\n" + "=" * 80)
        print("GPT-5.2-CHAT SUMMARY (with Bing Grounding)")
        print("=" * 80)
        print(f"\n{result['summary']}\n")
        
        if result['citations']:
            print("\nCitations:")
            for i, citation in enumerate(result['citations'], 1):
                print(f"{i}. {citation['url']}")
        
        # Save to markdown
        output_file = save_results_to_markdown(result)
        print(f"\n✅ Results saved to: {output_file}")
        
        logger.info("Processing complete!")
        return 0
        
    except Exception as e:
        logger.error(f"Error: {e}", exc_info=True)
        return 1

if __name__ == "__main__":
    exit(main())
