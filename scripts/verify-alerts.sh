#!/bin/bash
# التحقق من أن التنبيهات تعمل بشكل صحيح

echo "🔔 Verifying Alert System"
echo "========================="

# 1. التحقق من قواعد Prometheus
echo "1. Checking Prometheus rules..."
RULES=$(kubectl get prometheusrules -n monitoring -o name)
if [ -z "$RULES" ]; then
    echo "❌ No Prometheus rules found"
else
    echo "✅ Found rules:"
    echo "$RULES"
fi

# 2. التحقق من Alertmanager
echo ""
echo "2. Checking Alertmanager..."
AM_STATUS=$(kubectl get pods -n monitoring -l app=alertmanager -o jsonpath='{.items[0].status.phase}')
if [ "$AM_STATUS" == "Running" ]; then
    echo "✅ Alertmanager is running"
else
    echo "❌ Alertmanager status: $AM_STATUS"
fi

# 3. تشغيل port-forward للتحقق يدوياً
echo ""
echo "3. Starting port-forward for manual verification..."
echo "   Prometheus:  http://localhost:9090/alerts"
echo "   Alertmanager: http://localhost:9093"
echo "   Grafana:     http://localhost:3000"
echo ""
echo "Press Ctrl+C to stop all port-forwards"

# تشغيل port-forwards في الخلفية
kubectl port-forward svc/prometheus-stack-kube-prom-prometheus 9090:9090 -n monitoring &
PROM_PID=$!

kubectl port-forward svc/prometheus-stack-kube-prom-alertmanager 9093:9093 -n monitoring &
AM_PID=$!

kubectl port-forward svc/prometheus-stack-grafana 3000:80 -n monitoring &
GRAFANA_PID=$!

# انتظار الإنهاء
wait $PROM_PID $AM_PID $GRAFANA_PID