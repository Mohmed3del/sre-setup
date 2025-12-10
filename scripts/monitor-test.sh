#!/bin/bash
# مراقبة اختبارات الفشل في الوقت الحقيقي

NAMESPACE=${1:-"production"}
INTERVAL=${2:-"5"}

echo "👁️  Monitoring Failure Tests - Namespace: $NAMESPACE"
echo "Press Ctrl+C to stop"
echo ""

while true; do
    clear
    echo "⏰ $(date)"
    echo "========================================"
    
    # حالة الـ Pods
    echo "📦 POD STATUS:"
    kubectl get pods -n $NAMESPACE -o wide | head -20
    
    # حالة الـ Deployments
    echo ""
    echo "🚀 DEPLOYMENTS:"
    kubectl get deployments -n $NAMESPACE
    
    # أحداث حديثة
    echo ""
    echo "🔔 RECENT EVENTS:"
    kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10
    
    # حالة الـ HPA
    echo ""
    echo "📈 HPA STATUS:"
    kubectl get hpa -n $NAMESPACE 2>/dev/null || echo "No HPA configured"
    
    # استخدام الموارد
    echo ""
    echo "💾 RESOURCE USAGE:"
    kubectl top pods -n $NAMESPACE 2>/dev/null || echo "Metrics not available"
    
    sleep $INTERVAL
done