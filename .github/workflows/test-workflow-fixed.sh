#!/bin/bash

# Create a fixed version of the test-workflow target for the Makefile
cat > /tmp/test-workflow-target.txt << 'EOF'
test-workflow:
	@echo "🔍 Testing GitHub workflow with Act..."
	@if [ -z "$(WORKFLOW)" ]; then \
		echo "\n📚 Select workflow category:"; \
		PS3="Enter number: "; \
		categories=("Branch" "CI/CD" "Utils" "All" "Run All"); \
		select category in $${categories[@]}; do \
			if [ -n "$$category" ]; then \
				case $$category in \
					"Branch") \
						echo "\n📚 Branch Workflows:"; \
						workflows=($$(find .github/workflows/branch -name "*.yml" | sort)); \
						;; \
					"CI/CD") \
						echo "\n📚 CI/CD Workflows:"; \
						workflows=($$(find .github/workflows/ci -name "*.yml" | sort)); \
						;; \
					"Utils") \
						echo "\n📚 Utility Workflows:"; \
						workflows=($$(find .github/workflows/utils -name "*.yml" | sort)); \
						;; \
					"All") \
						echo "\n📚 All Workflows:"; \
						workflows=($$(find .github/workflows/branch .github/workflows/ci .github/workflows/utils -name "*.yml" | sort)); \
						;; \
					"Run All") \
						echo "\n📚 Running All Workflows..."; \
						workflows=($$(find .github/workflows/branch .github/workflows/ci .github/workflows/utils -name "*.yml" | sort)); \
						echo "\n📚 Select an event type:"; \
						events=("push" "pull_request" "workflow_dispatch"); \
						select event in "$${events[@]}"; do \
							if [ -n "$$event" ]; then \
								echo "\n📚 Testing all workflows with event: $$event"; \
								for w in "$${workflows[@]}"; do \
									workflow_name="$${w##*/}"; \
									echo "\n📚 Testing workflow: $$workflow_name"; \
									./.github/workflows/utils/test-workflow.sh $$workflow_name $$event || echo "\n⚠️ Workflow $$workflow_name failed"; \
								done; \
								break; \
							fi; \
						done; \
						break; \
						;; \
				esac; \
				if [ "$$category" != "Run All" ]; then \
					if [ $${#workflows[@]} -eq 0 ]; then \
						echo "\n⚠️ No workflows found in this category."; \
						break; \
					fi; \
					echo "\n📚 Select a workflow to test:"; \
					PS3="Enter number: "; \
					workflow_names=(); \
					for w in "$${workflows[@]}"; do \
						workflow_names+=("$${w##*/}"); \
					done; \
					select workflow in "$${workflow_names[@]}"; do \
						if [ -n "$$workflow" ]; then \
							echo "\n📚 Selected workflow: $$workflow"; \
							echo "\n📚 Select an event type:"; \
							events=("push" "pull_request" "workflow_dispatch"); \
							select event in "$${events[@]}"; do \
								if [ -n "$$event" ]; then \
									echo "\n📚 Selected event: $$event"; \
									echo "\n📚 Enter a specific job to test (leave empty for all jobs):"; \
									read -p "Job name: " job; \
									workflow_filename="$${workflow##*/}"; \
									if [ -n "$$job" ]; then \
										./.github/workflows/utils/test-workflow.sh $$workflow_filename $$event $$job; \
									else \
										./.github/workflows/utils/test-workflow.sh $$workflow_filename $$event; \
									fi; \
									break; \
								fi; \
							done; \
							break; \
						fi; \
					done; \
				fi; \
				break; \
			fi; \
		done; \
	else \
		EVENT=$${EVENT:-push}; \
		JOB=$${JOB:-""}; \
		WORKFLOW_FILENAME="$${WORKFLOW##*/}"; \
		if [ -n "$$JOB" ]; then \
			./.github/workflows/utils/test-workflow.sh $$WORKFLOW_FILENAME $$EVENT $$JOB; \
		else \
			./.github/workflows/utils/test-workflow.sh $$WORKFLOW_FILENAME $$EVENT; \
		fi; \
	fi
	@echo "✅ Workflow test complete!"
EOF

echo "Fixed Makefile target created at /tmp/test-workflow-target.txt"
echo "Run the following command to update your Makefile:"
echo "sed -i '' '185,260d' /Users/jaronschulz/Projects/Code/--Learning/dataScientest_devOps/+++Project/fastAPI-project-app/Makefile && cat /tmp/test-workflow-target.txt >> /Users/jaronschulz/Projects/Code/--Learning/dataScientest_devOps/+++Project/fastAPI-project-app/Makefile"
