#!/bin/bash
# التحقق من أن التطبيقات تقوم بتصدير الـ Metrics

SERVICE=${1:-"api-service"}
NAMESPACE=${2:-"production"}

echo "📊 Checking Metrics Export for $SERVICE"
echo "========================================"

# الحصول على Pod
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=$SERVICE -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
    echo "❌ No pod found for service $SERVICE"
    exit 1
fi

echo "Pod: $POD_NAME"

# التحقق من annotations
echo ""
echo "1. Checking Prometheus annotations:"
kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.metadata.annotations}' | jq .

# اختبار endpoint الـ metrics
echo ""
echo "2. Testing /metrics endpoint:"
kubectl exec $POD_NAME -n $NAMESPACE -- curl -s http://localhost:8080/metrics | head -20

# التحقق من الـ metrics المخصصة
echo ""
echo "3. Looking for custom metrics:"
METRICS=$(kubectl exec $POD_NAME -n $NAMESPACE -- curl -s http://localhost:8080/metrics)

if echo "$METRICS" | grep -q "http_requests_total"; then
    echo "✅ Found: http_requests_total"
else
    echo "❌ Missing: http_requests_total"
fi

if echo "$METRICS" | grep -q "http_request_duration_seconds"; then
    echo "✅ Found: http_request_duration_seconds"
else
    echo "❌ Missing: http_request_duration_seconds"
fi

if echo "$METRICS" | grep -q "database_connection_errors_total"; then
    echo "✅ Found: database_connection_errors_total"
else
    echo "❌ Missing: database_connection_errors_total"
fi

echo ""
echo "✅ Metrics check completed"