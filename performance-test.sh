#!/bin/bash
# Performance test to measure the overhead of find filtering vs no filtering
#
# This test demonstrates the performance difference between using find with
# ownership/permission filters versus processing all files directly.
#
# Usage: ./performance-test.sh [number_of_files]
#
# The test creates a temporary Drupal-like directory structure and measures
# the time taken by find commands with and without filtering.

# Configuration
NUM_FILES=${1:-25000}  # Default to 25,000 files (configurable)
TEST_DIR="/tmp/drupal-perf-test-$$"
TEST_USER=$(whoami)
TEST_GROUP=$(id -gn)

echo "=== Performance Test for Find Filtering ==="
echo ""
echo "This test measures the overhead of checking file ownership and permissions"
echo "versus processing all files directly."
echo ""

# Cleanup function
cleanup() {
    echo "Cleaning up test directory..."
    rm -rf "$TEST_DIR"
}

trap cleanup EXIT

# Create test directory structure
echo "Creating test directory structure with $NUM_FILES files..."
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Create a realistic directory structure
mkdir -p core/modules/system
mkdir -p modules/contrib
mkdir -p sites/default/files
mkdir -p themes
mkdir -p vendor

# Create files distributed across directories
echo "Creating files (this may take a moment)..."

# Distribute files across directories
FILES_PER_DIR=$((NUM_FILES / 5))

for i in $(seq 1 $FILES_PER_DIR); do
    mkdir -p "core/dir_$i" 2>/dev/null
    touch "core/dir_$i/file.php"
done &
PID1=$!

for i in $(seq 1 $FILES_PER_DIR); do
    mkdir -p "modules/contrib/module_$i" 2>/dev/null
    touch "modules/contrib/module_$i/file.php"
done &
PID2=$!

for i in $(seq 1 $FILES_PER_DIR); do
    touch "vendor/file_$i.php"
done &
PID3=$!

for i in $(seq 1 $FILES_PER_DIR); do
    touch "sites/default/files/file_$i.jpg"
done &
PID4=$!

for i in $(seq 1 $FILES_PER_DIR); do
    touch "themes/file_$i.php"
done &
PID5=$!

# Wait for all background jobs to complete
wait $PID1 $PID2 $PID3 $PID4 $PID5

TOTAL_FILES=$(find "$TEST_DIR" -type f | wc -l)
TOTAL_ITEMS=$(find "$TEST_DIR" \( -type f -o -type d \) | wc -l)
echo "Created $TOTAL_FILES files and $TOTAL_ITEMS total items (files + directories)"
echo ""

# Test scenarios
echo "Running performance tests..."
echo ""

# Scenario 1: Ownership filtering when all files need changes
echo "Scenario 1: Ownership filtering (worst case - all files need changes)"
echo "-----------------------------------------------------------------------"
echo "Test 1a: Find WITH ownership filtering"
TIME1_START=$(date +%s.%N)
COUNT1=$(find "$TEST_DIR" \( ! -user "root" -o ! -group "root" \) \( -type f -o -type d \) 2>/dev/null | wc -l)
TIME1_END=$(date +%s.%N)
TIME1=$(echo "$TIME1_END - $TIME1_START" | bc)
echo "  Items found needing changes: $COUNT1"
echo "  Time: ${TIME1}s"

echo "Test 1b: Find WITHOUT filtering"
TIME2_START=$(date +%s.%N)
COUNT2=$(find "$TEST_DIR" \( -type f -o -type d \) | wc -l)
TIME2_END=$(date +%s.%N)
TIME2=$(echo "$TIME2_END - $TIME2_START" | bc)
echo "  Total items: $COUNT2"
echo "  Time: ${TIME2}s"

DIFF1=$(echo "$TIME1 - $TIME2" | bc)
if (( $(echo "$TIME1 > $TIME2" | bc -l) )); then
    PERCENT1=$(echo "scale=1; (($TIME1 - $TIME2) / $TIME2) * 100" | bc)
else
    PERCENT1=0
fi
echo "  Overhead: ${DIFF1}s (${PERCENT1}%)"
echo ""

# Scenario 2: Permission filtering
echo "Scenario 2: Permission filtering"
echo "-----------------------------------------------------------------------"
echo "Test 2a: Find WITH permission filtering"
TIME3_START=$(date +%s.%N)
COUNT3=$(find "$TEST_DIR" -type f ! -perm 0644 | wc -l)
TIME3_END=$(date +%s.%N)
TIME3=$(echo "$TIME3_END - $TIME3_START" | bc)
echo "  Files with wrong permissions: $COUNT3"
echo "  Time: ${TIME3}s"

echo "Test 2b: Find WITHOUT permission filtering"
TIME4_START=$(date +%s.%N)
COUNT4=$(find "$TEST_DIR" -type f | wc -l)
TIME4_END=$(date +%s.%N)
TIME4=$(echo "$TIME4_END - $TIME4_START" | bc)
echo "  Total files: $COUNT4"
echo "  Time: ${TIME4}s"

DIFF2=$(echo "$TIME3 - $TIME4" | bc)
if (( $(echo "$TIME3 > $TIME4" | bc -l) )); then
    PERCENT2=$(echo "scale=1; (($TIME3 - $TIME4) / $TIME4) * 100" | bc)
else
    PERCENT2=0
fi
echo "  Overhead: ${DIFF2}s (${PERCENT2}%)"
echo ""

# Summary
echo "=== SUMMARY ==="
echo "Total items processed: $TOTAL_ITEMS files and directories"
echo ""
echo "Ownership check overhead: ${PERCENT1}%"
echo "Permission check overhead: ${PERCENT2}%"
echo ""

# Calculate average overhead
AVG_OVERHEAD=$(echo "scale=1; ($PERCENT1 + $PERCENT2) / 2" | bc)
echo "Average filtering overhead: ${AVG_OVERHEAD}%"
echo ""

if (( $(echo "$AVG_OVERHEAD > 20" | bc -l) )); then
    echo "CONCLUSION: Filtering overhead is SIGNIFICANT (>20%)"
    echo "  The --skip-checks option provides substantial performance benefit"
    echo "  when most or all files need changes."
elif (( $(echo "$AVG_OVERHEAD > 10" | bc -l) )); then
    echo "CONCLUSION: Filtering overhead is MODERATE (10-20%)"
    echo "  The --skip-checks option may be beneficial for very large installations."
else
    echo "CONCLUSION: Filtering overhead is MINIMAL (<10%)"
    echo "  Current filtering approach is efficient for most use cases."
fi

echo ""
echo "Note: Performance characteristics vary based on:"
echo "  - Number of files (more files = more overhead)"
echo "  - Storage speed (slower storage = more overhead)"
echo "  - Percentage of files needing changes"
echo "  - System load and available I/O bandwidth"
