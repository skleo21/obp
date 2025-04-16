# scripts/compare_deployments.py
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os
import argparse

def load_performance_data(file_path):
    """Load performance data from CSV file"""
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Performance file not found: {file_path}")
    
    return pd.read_csv(file_path)

def compare_deployments(cicd_file, manual_file, output_dir="results"):
    """Compare CI/CD vs manual deployment performance"""
    # Load data
    cicd_data = load_performance_data(cicd_file)
    manual_data = load_performance_data(manual_file)
    
    # Add deployment type
    cicd_data["deployment"] = "CI/CD"
    manual_data["deployment"] = "Manual"
    
    # Combine datasets
    combined_data = pd.concat([cicd_data, manual_data])
    
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # 1. Response time comparison by endpoint
    plt.figure(figsize=(12, 6))
    sns.boxplot(x="endpoint", y="response_time", hue="deployment", data=combined_data)
    plt.title("Response Time by Endpoint (CI/CD vs Manual)")
    plt.xlabel("Endpoint")
    plt.ylabel("Response Time (ms)")
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig(f"{output_dir}/response_time_comparison.png")
    
    # 2. Success rate comparison
    success_rate = combined_data.groupby(["deployment", "endpoint"])["success"].mean().reset_index()
    success_rate["success_percentage"] = success_rate["success"] * 100
    
    plt.figure(figsize=(12, 6))
    sns.barplot(x="endpoint", y="success_percentage", hue="deployment", data=success_rate)
    plt.title("Success Rate by Endpoint (CI/CD vs Manual)")
    plt.xlabel("Endpoint")
    plt.ylabel("Success Rate (%)")
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig(f"{output_dir}/success_rate_comparison.png")
    
    # 3. Generate summary statistics
    summary = combined_data.groupby("deployment").agg({
        "response_time": ["mean", "median", "std", "min", "max"],
        "success": ["mean", "count"]
    }).reset_index()
    
    summary.columns = ["deployment", "mean_response_time", "median_response_time", 
                      "std_response_time", "min_response_time", "max_response_time",
                      "success_rate", "total_requests"]
    
    summary["success_rate"] = summary["success_rate"] * 100
    
    # Save summary to CSV
    summary.to_csv(f"{output_dir}/deployment_comparison_summary.csv", index=False)
    
    print("Comparison completed. Results saved to:", output_dir)
    return summary

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Compare CI/CD vs Manual deployments')
    parser.add_argument('--cicd', required=True, help='Path to CI/CD performance results CSV')
    parser.add_argument('--manual', required=True, help='Path to manual deployment performance results CSV')
    parser.add_argument('--output', default='results', help='Output directory for results')
    
    args = parser.parse_args()
    summary = compare_deployments(args.cicd, args.manual, args.output)
    print("\nSummary Statistics:")
    print(summary)