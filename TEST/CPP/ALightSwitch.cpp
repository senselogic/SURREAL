#include "BasicClasses.h"
#include "LightSwitch.h"

ALightSwitch::ALightSwitch(
     )
{
    DesiredIntensity = 3000.0f;

    PointLightComponent = CreateDefaultSubobject<UPointLightComponent>( TEXT( "PointLightComponent" ) );
    PointLightComponent->Intensity = DesiredIntensity;
    PointLightComponent->bVisible = true;
    RootComponent = PointLightComponent;

    SphereComponent = CreateDefaultSubobject<USphereComponent>( TEXT( "SphereComponent" ) );
    SphereComponent->InitSphereRadius( 250.0f );
    SphereComponent->SetupAttachment( RootComponent );

    SphereComponent->OnComponentBeginOverlap.AddDynamic( this, &ALightSwitch::OnOverlapBegin );
    SphereComponent->OnComponentEndOverlap.AddDynamic( this, &ALightSwitch::OnOverlapEnd );
}

void ALightSwitch::OnOverlapBegin(
    class UPrimitiveComponent* overlapped_primitive_component,
    class AActor* other_actor,
    class UPrimitiveComponent* other_primitive_component,
    int32 other_body_index,
    bool is_from_sweep,
    const FHitResult& sweep_hit_result
    )
{
    if ( other_actor && ( other_actor != this ) && other_primitive_component )
    {
        ToggleLight();
    }
}

void ALightSwitch::OnOverlapEnd(
    class UPrimitiveComponent* overlapped_primitive_component,
    class AActor* other_actor,
    class UPrimitiveComponent* other_primitive_component,
    int32 other_body_index
    )
{
    if ( other_actor && ( other_actor != this ) && other_primitive_component )
    {
        ToggleLight();
    }
}

void ALightSwitch::ToggleLight(
    )
{
    PointLightComponent->ToggleVisibility();
}
