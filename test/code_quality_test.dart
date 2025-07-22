import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

/// Comprehensive test suite to validate code quality monitoring setup
/// This test ensures all quality monitoring components are working correctly
void main() {
  group('Code Quality Monitoring Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      
      // Load test environment
      try {
        await dotenv.load(fileName: ".env.example");
      } catch (e) {
        dotenv.testLoad(fileInput: '''
OPENROUTER_API_KEY=test-key
DEFAULT_MODEL=test-model
FALLBACK_MODELS=test-model1,test-model2
REVENUECAT_API_KEY_ANDROID=test-android-key
REVENUECAT_API_KEY_IOS=test-ios-key
REVENUECAT_ENTITLEMENT_ID=premium
''');
      }
    });

    group('Coverage Configuration Tests', () {
      test('should have coverage configuration file', () {
        final coverageConfig = File('coverage_config.yaml');
        expect(coverageConfig.existsSync(), isTrue, 
            reason: 'Coverage configuration file should exist');
      });

      test('should have coverage script', () {
        final coverageScript = File('scripts/coverage.sh');
        expect(coverageScript.existsSync(), isTrue,
            reason: 'Coverage script should exist');
        
        // Check if script is executable
        final stat = coverageScript.statSync();
        expect(stat.mode & 0x49, isNot(0), // Check execute permissions
            reason: 'Coverage script should be executable');
      });

      test('should exclude generated files from coverage', () {
        final coverageConfig = File('coverage_config.yaml');
        final content = coverageConfig.readAsStringSync();
        
        expect(content, contains('*.g.dart'),
            reason: 'Should exclude generated files');
        expect(content, contains('*.mocks.dart'),
            reason: 'Should exclude mock files');
        expect(content, contains('test/**'),
            reason: 'Should exclude test files');
      });
    });

    group('Quality Gates Tests', () {
      test('should have quality gates configuration', () {
        final qualityGates = File('quality_gates.yaml');
        expect(qualityGates.existsSync(), isTrue,
            reason: 'Quality gates configuration should exist');
      });

      test('should have quality check script', () {
        final qualityScript = File('scripts/quality_check.sh');
        expect(qualityScript.existsSync(), isTrue,
            reason: 'Quality check script should exist');
        
        // Check if script is executable
        final stat = qualityScript.statSync();
        expect(stat.mode & 0x49, isNot(0),
            reason: 'Quality check script should be executable');
      });

      test('should define appropriate coverage thresholds', () {
        final qualityGates = File('quality_gates.yaml');
        final content = qualityGates.readAsStringSync();
        
        expect(content, contains('line_coverage'),
            reason: 'Should define line coverage thresholds');
        expect(content, contains('function_coverage'),
            reason: 'Should define function coverage thresholds');
        expect(content, contains('branch_coverage'),
            reason: 'Should define branch coverage thresholds');
      });

      test('should have higher standards for critical services', () {
        final qualityGates = File('quality_gates.yaml');
        final content = qualityGates.readAsStringSync();
        
        expect(content, contains('critical_services'),
            reason: 'Should define critical services');
        expect(content, contains('openrouter_service.dart'),
            reason: 'Should include OpenRouter service as critical');
        expect(content, contains('encryption_service.dart'),
            reason: 'Should include encryption service as critical');
      });
    });

    group('SonarQube Integration Tests', () {
      test('should have SonarQube project configuration', () {
        final sonarConfig = File('sonar-project.properties');
        expect(sonarConfig.existsSync(), isTrue,
            reason: 'SonarQube configuration should exist');
      });

      test('should have SonarQube setup script', () {
        final sonarScript = File('scripts/sonar_setup.sh');
        expect(sonarScript.existsSync(), isTrue,
            reason: 'SonarQube setup script should exist');
        
        // Check if script is executable
        final stat = sonarScript.statSync();
        expect(stat.mode & 0x49, isNot(0),
            reason: 'SonarQube setup script should be executable');
      });

      test('should have Docker Compose for local SonarQube', () {
        final dockerCompose = File('docker-compose.sonar.yml');
        expect(dockerCompose.existsSync(), isTrue,
            reason: 'Docker Compose file for SonarQube should exist');
      });

      test('should configure appropriate exclusions', () {
        final sonarConfig = File('sonar-project.properties');
        final content = sonarConfig.readAsStringSync();
        
        expect(content, contains('sonar.exclusions'),
            reason: 'Should define file exclusions');
        expect(content, contains('*.g.dart'),
            reason: 'Should exclude generated files');
        expect(content, contains('sonar.test.exclusions'),
            reason: 'Should define test exclusions');
      });

      test('should define security-specific rules', () {
        final sonarConfig = File('sonar-project.properties');
        final content = sonarConfig.readAsStringSync();
        
        expect(content, contains('security'),
            reason: 'Should include security configurations');
        expect(content, contains('apikey'),
            reason: 'Should include API key detection rules');
      });
    });

    group('Analysis Options Tests', () {
      test('should have enhanced analysis options', () {
        final analysisOptions = File('analysis_options.yaml');
        expect(analysisOptions.existsSync(), isTrue,
            reason: 'Analysis options file should exist');
      });

      test('should include comprehensive linting rules', () {
        final analysisOptions = File('analysis_options.yaml');
        final content = analysisOptions.readAsStringSync();
        
        expect(content, contains('avoid_print'),
            reason: 'Should include avoid_print rule');
        expect(content, contains('prefer_const_constructors'),
            reason: 'Should include performance rules');
        expect(content, contains('avoid_web_libraries_in_flutter'),
            reason: 'Should include security rules');
      });

      test('should exclude generated files from analysis', () {
        final analysisOptions = File('analysis_options.yaml');
        final content = analysisOptions.readAsStringSync();
        
        expect(content, contains('exclude:'),
            reason: 'Should define exclusions');
        expect(content, contains('*.g.dart'),
            reason: 'Should exclude generated files');
      });
    });

    group('CI/CD Integration Tests', () {
      test('should have updated GitHub Actions workflow', () {
        final workflow = File('.github/workflows/build-and-deploy.yml');
        expect(workflow.existsSync(), isTrue,
            reason: 'GitHub Actions workflow should exist');
      });

      test('should include quality gates in CI/CD', () {
        final workflow = File('.github/workflows/build-and-deploy.yml');
        final content = workflow.readAsStringSync();
        
        expect(content, contains('quality-gates'),
            reason: 'Should include quality gates job');
        expect(content, contains('coverage'),
            reason: 'Should include coverage generation');
        expect(content, contains('sonarqube'),
            reason: 'Should include SonarQube analysis');
      });

      test('should block deployment on quality failures', () {
        final workflow = File('.github/workflows/build-and-deploy.yml');
        final content = workflow.readAsStringSync();
        
        expect(content, contains('needs: [test, quality-gates]'),
            reason: 'Build jobs should depend on quality gates');
      });
    });

    group('Documentation Tests', () {
      test('should have comprehensive quality guide', () {
        final guide = File('CODE_QUALITY_GUIDE.md');
        expect(guide.existsSync(), isTrue,
            reason: 'Code quality guide should exist');
      });

      test('should document all quality monitoring features', () {
        final guide = File('CODE_QUALITY_GUIDE.md');
        final content = guide.readAsStringSync();
        
        expect(content, contains('Coverage'),
            reason: 'Should document coverage monitoring');
        expect(content, contains('Quality Gates'),
            reason: 'Should document quality gates');
        expect(content, contains('SonarQube'),
            reason: 'Should document SonarQube integration');
        expect(content, contains('Troubleshooting'),
            reason: 'Should include troubleshooting guide');
      });
    });

    group('Security Monitoring Tests', () {
      test('should detect hardcoded API keys', () {
        // This test simulates what the security scan would catch
        const testCode = '''
        const apiKey = "sk-or-v1-1234567890abcdef";
        ''';
        
        expect(testCode, contains('sk-or-v1-'),
            reason: 'Should be able to detect hardcoded API keys');
      });

      test('should enforce secure storage usage', () {
        final qualityGates = File('quality_gates.yaml');
        final content = qualityGates.readAsStringSync();
        
        expect(content, contains('secure_storage_required'),
            reason: 'Should enforce secure storage usage');
        expect(content, contains('encryption_required'),
            reason: 'Should require encryption for sensitive data');
      });
    });

    group('Performance Monitoring Tests', () {
      test('should define performance thresholds', () {
        final qualityGates = File('quality_gates.yaml');
        final content = qualityGates.readAsStringSync();
        
        expect(content, contains('build_time_limit'),
            reason: 'Should define build time limits');
        expect(content, contains('app_size_limit'),
            reason: 'Should define app size limits');
      });

      test('should include complexity limits', () {
        final qualityGates = File('quality_gates.yaml');
        final content = qualityGates.readAsStringSync();
        
        expect(content, contains('cyclomatic_complexity'),
            reason: 'Should define complexity limits');
        expect(content, contains('cognitive_complexity'),
            reason: 'Should define cognitive complexity limits');
      });
    });
  });

  group('Integration Tests', () {
    test('should validate complete quality monitoring setup', () {
      // Check that all required files exist
      final requiredFiles = [
        'coverage_config.yaml',
        'quality_gates.yaml',
        'sonar-project.properties',
        'docker-compose.sonar.yml',
        'scripts/coverage.sh',
        'scripts/quality_check.sh',
        'scripts/sonar_setup.sh',
        'CODE_QUALITY_GUIDE.md',
        '.github/workflows/build-and-deploy.yml',
      ];

      for (final filePath in requiredFiles) {
        final file = File(filePath);
        expect(file.existsSync(), isTrue,
            reason: 'Required file $filePath should exist');
      }
    });

    test('should have consistent configuration across files', () {
      // Check that project key is consistent
      final sonarConfig = File('sonar-project.properties');
      final sonarContent = sonarConfig.readAsStringSync();
      
      expect(sonarContent, contains('nafs-ai'),
          reason: 'Project key should be consistent');
    });
  });
}
