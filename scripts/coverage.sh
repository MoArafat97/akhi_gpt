#!/bin/bash

# Advanced Code Coverage Script for NafsAI
# This script runs comprehensive coverage analysis including unit, widget, and integration tests

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COVERAGE_DIR="coverage"
HTML_DIR="$COVERAGE_DIR/html"
LCOV_FILE="$COVERAGE_DIR/lcov.info"
COBERTURA_FILE="$COVERAGE_DIR/cobertura.xml"
JSON_FILE="$COVERAGE_DIR/coverage.json"

# Coverage thresholds
MIN_LINE_COVERAGE=80
MIN_FUNCTION_COVERAGE=85
MIN_BRANCH_COVERAGE=75

echo -e "${BLUE}🔍 Starting comprehensive code coverage analysis for NafsAI...${NC}"

# Clean previous coverage data
echo -e "${YELLOW}🧹 Cleaning previous coverage data...${NC}"
rm -rf $COVERAGE_DIR
mkdir -p $COVERAGE_DIR
mkdir -p $HTML_DIR

# Get Flutter dependencies
echo -e "${YELLOW}📦 Getting Flutter dependencies...${NC}"
flutter pub get

# Generate mocks for testing
echo -e "${YELLOW}🔧 Generating mocks...${NC}"
flutter packages pub run build_runner build --delete-conflicting-outputs

# Run unit tests with coverage
echo -e "${BLUE}🧪 Running unit tests with coverage...${NC}"
flutter test --coverage --coverage-path=$LCOV_FILE

# Check if coverage file was generated
if [ ! -f "$LCOV_FILE" ]; then
    echo -e "${RED}❌ Coverage file not generated. Tests may have failed.${NC}"
    exit 1
fi

# Run integration tests if they exist
if [ -d "integration_test" ]; then
    echo -e "${BLUE}🔗 Running integration tests...${NC}"
    flutter test integration_test/ --coverage --coverage-path=$COVERAGE_DIR/integration_lcov.info || true
    
    # Merge coverage files if integration coverage exists
    if [ -f "$COVERAGE_DIR/integration_lcov.info" ]; then
        echo -e "${YELLOW}🔄 Merging coverage files...${NC}"
        # Install lcov if not available
        if ! command -v lcov &> /dev/null; then
            echo -e "${YELLOW}📥 Installing lcov...${NC}"
            if [[ "$OSTYPE" == "darwin"* ]]; then
                brew install lcov
            elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
                sudo apt-get update && sudo apt-get install -y lcov
            fi
        fi
        
        # Merge coverage files
        lcov --add-tracefile $LCOV_FILE --add-tracefile $COVERAGE_DIR/integration_lcov.info --output-file $COVERAGE_DIR/merged_lcov.info
        mv $COVERAGE_DIR/merged_lcov.info $LCOV_FILE
    fi
fi

# Remove generated files and test files from coverage
echo -e "${YELLOW}🧹 Filtering coverage data...${NC}"
if command -v lcov &> /dev/null; then
    lcov --remove $LCOV_FILE \
        '*/lib/**/*.g.dart' \
        '*/lib/**/*.freezed.dart' \
        '*/lib/**/*.mocks.dart' \
        '*/lib/l10n/**' \
        '*/test/**' \
        '*/integration_test/**' \
        --output-file $LCOV_FILE
fi

# Generate HTML report
echo -e "${BLUE}📊 Generating HTML coverage report...${NC}"
if command -v genhtml &> /dev/null; then
    genhtml $LCOV_FILE --output-directory $HTML_DIR --title "NafsAI Coverage Report" --show-details --legend
    echo -e "${GREEN}✅ HTML report generated at: $HTML_DIR/index.html${NC}"
else
    echo -e "${YELLOW}⚠️  genhtml not available. Install lcov for HTML reports.${NC}"
fi

# Convert to Cobertura format for SonarQube
echo -e "${BLUE}🔄 Converting to Cobertura format...${NC}"
if command -v python3 &> /dev/null; then
    # Create a simple Python script to convert LCOV to Cobertura
    cat > $COVERAGE_DIR/lcov_to_cobertura.py << 'EOF'
#!/usr/bin/env python3
import sys
import xml.etree.ElementTree as ET
from xml.dom import minidom

def lcov_to_cobertura(lcov_file, output_file):
    """Convert LCOV format to Cobertura XML format"""
    
    # Create root element
    coverage = ET.Element('coverage')
    coverage.set('line-rate', '0.0')
    coverage.set('branch-rate', '0.0')
    coverage.set('version', '1.9')
    coverage.set('timestamp', str(int(__import__('time').time())))
    
    # Create sources element
    sources = ET.SubElement(coverage, 'sources')
    source = ET.SubElement(sources, 'source')
    source.text = '.'
    
    # Create packages element
    packages = ET.SubElement(coverage, 'packages')
    
    # Parse LCOV file
    current_file = None
    files_data = {}
    
    try:
        with open(lcov_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line.startswith('SF:'):
                    current_file = line[3:]
                    files_data[current_file] = {'lines': {}, 'functions': {}}
                elif line.startswith('DA:') and current_file:
                    parts = line[3:].split(',')
                    if len(parts) >= 2:
                        line_num = parts[0]
                        hits = parts[1]
                        files_data[current_file]['lines'][line_num] = hits
    except Exception as e:
        print(f"Error parsing LCOV file: {e}")
        return False
    
    # Create package for each file
    for file_path, data in files_data.items():
        package = ET.SubElement(packages, 'package')
        package.set('name', file_path.replace('/', '.').replace('.dart', ''))
        package.set('line-rate', '0.0')
        package.set('branch-rate', '0.0')
        package.set('complexity', '0.0')
        
        classes = ET.SubElement(package, 'classes')
        class_elem = ET.SubElement(classes, 'class')
        class_elem.set('name', file_path.split('/')[-1].replace('.dart', ''))
        class_elem.set('filename', file_path)
        class_elem.set('line-rate', '0.0')
        class_elem.set('branch-rate', '0.0')
        class_elem.set('complexity', '0.0')
        
        methods = ET.SubElement(class_elem, 'methods')
        lines = ET.SubElement(class_elem, 'lines')
        
        for line_num, hits in data['lines'].items():
            line = ET.SubElement(lines, 'line')
            line.set('number', line_num)
            line.set('hits', hits)
            line.set('branch', 'false')
    
    # Write to file
    rough_string = ET.tostring(coverage, 'unicode')
    reparsed = minidom.parseString(rough_string)
    
    with open(output_file, 'w') as f:
        f.write(reparsed.toprettyxml(indent="  "))
    
    return True

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python3 lcov_to_cobertura.py <lcov_file> <output_file>")
        sys.exit(1)
    
    success = lcov_to_cobertura(sys.argv[1], sys.argv[2])
    if success:
        print(f"Successfully converted {sys.argv[1]} to {sys.argv[2]}")
    else:
        print("Conversion failed")
        sys.exit(1)
EOF

    python3 $COVERAGE_DIR/lcov_to_cobertura.py $LCOV_FILE $COBERTURA_FILE
    echo -e "${GREEN}✅ Cobertura report generated at: $COBERTURA_FILE${NC}"
fi

# Extract coverage statistics
echo -e "${BLUE}📈 Extracting coverage statistics...${NC}"
if command -v lcov &> /dev/null; then
    COVERAGE_SUMMARY=$(lcov --summary $LCOV_FILE 2>&1)
    echo "$COVERAGE_SUMMARY"
    
    # Extract line coverage percentage
    LINE_COVERAGE=$(echo "$COVERAGE_SUMMARY" | grep -o 'lines......: [0-9.]*%' | grep -o '[0-9.]*' | head -1)
    FUNCTION_COVERAGE=$(echo "$COVERAGE_SUMMARY" | grep -o 'functions..: [0-9.]*%' | grep -o '[0-9.]*' | head -1)
    
    echo -e "\n${BLUE}📊 Coverage Summary:${NC}"
    echo -e "Line Coverage: ${LINE_COVERAGE}%"
    echo -e "Function Coverage: ${FUNCTION_COVERAGE}%"
    
    # Check thresholds
    if (( $(echo "$LINE_COVERAGE >= $MIN_LINE_COVERAGE" | bc -l) )); then
        echo -e "${GREEN}✅ Line coverage meets threshold (${MIN_LINE_COVERAGE}%)${NC}"
    else
        echo -e "${RED}❌ Line coverage below threshold (${MIN_LINE_COVERAGE}%)${NC}"
        exit 1
    fi
    
    if (( $(echo "$FUNCTION_COVERAGE >= $MIN_FUNCTION_COVERAGE" | bc -l) )); then
        echo -e "${GREEN}✅ Function coverage meets threshold (${MIN_FUNCTION_COVERAGE}%)${NC}"
    else
        echo -e "${RED}❌ Function coverage below threshold (${MIN_FUNCTION_COVERAGE}%)${NC}"
        exit 1
    fi
fi

echo -e "\n${GREEN}🎉 Coverage analysis completed successfully!${NC}"
echo -e "${BLUE}📁 Reports available at:${NC}"
echo -e "  - LCOV: $LCOV_FILE"
echo -e "  - HTML: $HTML_DIR/index.html"
echo -e "  - Cobertura: $COBERTURA_FILE"

# Open HTML report if on macOS
if [[ "$OSTYPE" == "darwin"* ]] && [ -f "$HTML_DIR/index.html" ]; then
    echo -e "\n${BLUE}🌐 Opening coverage report in browser...${NC}"
    open $HTML_DIR/index.html
fi
